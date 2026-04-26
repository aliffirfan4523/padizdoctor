import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';

// 1. Create a model to hold the combined data
class CombinedScan {
  final Map<String, dynamic> record;
  final Map<String, dynamic> image;
  final Map<String, dynamic> result;

  CombinedScan(
      {required this.record, required this.image, required this.result});
}

class ScanService {
  static Stream<List<Map<String, dynamic>>> getDetailedScans(String userId) {
    // Gate behind auth state — when the user signs out the stream
    // emits [] and stops all nested Firestore listeners, preventing
    // PERMISSION_DENIED errors from orphaned queries.
    return FirebaseAuth.instance.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
        .collection('DiagnosisRecord')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .switchMap((recordSnap) {
      if (recordSnap.docs.isEmpty) return Stream.value([]);

      final streams = recordSnap.docs.map((doc) {
        final recordData = doc.data();

        final imageStream = FirebaseFirestore.instance
            .collection('ImageFile')
            .doc(recordData['image_id'])
            .snapshots();

        final resultStream = FirebaseFirestore.instance
            .collection('DiagnosisResult')
            .where('record_id', isEqualTo: doc.id)
            .limit(1)
            .snapshots();

        return CombineLatestStream.combine2(
          imageStream,
          resultStream,
          (img, res) => (img: img, res: res),
        ).switchMap((data) {
          final resultData =
              data.res.docs.isNotEmpty ? data.res.docs.first.data() : null;
          final diseaseId = resultData?['disease_id'] as String?;

          if (diseaseId == null) {
            return Stream.value({
              'record': recordData,
              'record_id': doc.id,
              'image': data.img.data() ?? {},
              'result': resultData ?? {},
              'disease': {},
            });
          }

          return FirebaseFirestore.instance
              .collection('Disease')
              .doc(diseaseId)
              .snapshots()
              .map((diseaseDoc) => {
                    'record': recordData,
                    'record_id': doc.id,
                    'image': data.img.data() ?? {},
                    'result': resultData ?? {},
                    'disease': diseaseDoc.data() ?? {},
                  });
        });
      }).toList();
      return CombineLatestStream.list(streams);
    });
    }); // end authStateChanges switchMap
  }
}

// Logic to join the 4 collections needed for this screen
Future<Map<String, dynamic>> fetchFullAnalysisData(
    String recordId, String imageId) async {
  final db = FirebaseFirestore.instance;

  try {
    // 1. Get ALL Results for this record
    final resultSnap = await db
        .collection('DiagnosisResult')
        .where('record_id', isEqualTo: recordId)
        .get();

    if (resultSnap.docs.isEmpty) {
      throw "DiagnosisResult missing";
    }

    final resultsList = resultSnap.docs.map((doc) => doc.data()).toList();

    // 2. Fetch the image document & record document
    final imageDoc = await db.collection('ImageFile').doc(imageId).get();
    if (!imageDoc.exists) throw "Image document not found";

    final recordDoc = await db.collection('DiagnosisRecord').doc(recordId).get();

    // 3. Fetch unique diseases found in results
    final diseaseIds =
        resultsList.map((r) => r['disease_id'] as String).toSet().toList();
    final diseaseSnapshots = await Future.wait(
      diseaseIds.map((id) => db.collection('Disease').doc(id).get()),
    );

    final Map<String, dynamic> diseasesMap = <String, dynamic>{
      for (var doc in diseaseSnapshots)
        if (doc.exists) doc.id: doc.data()
    };

    // 4. Fetch all AI suggestions
    final suggestionSnap = await db
        .collection('TreatmentSuggestion')
        .where('record_id', isEqualTo: recordId)
        .get();

    return <String, dynamic>{
      'results': resultsList,
      'image': imageDoc.data(),
      'record': recordDoc.data(),
      'diseases': diseasesMap,
      'suggestions': suggestionSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Inject ID to match result ID
        return data;
      }).toList(),
    };
  } catch (e) {
    rethrow;
  }
}

Future<void> deleteDiagnosisRecord(
    String recordId, String userId, String imageId) async {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final batch = firestore.batch();

  try {
    print("DEBUG DELETE: recordId=$recordId, userId=$userId, imageId=$imageId");

    if (recordId == null || userId == null || imageId == null) {
      print("❌ ERROR: One of the required fields is NULL!");
      return;
    }
    // 1. Delete Image from Storage
    // Ensure you use the correct path: diagnosis_images/{userId}/{fileName}
    final imageDoc = await firestore.collection('ImageFile').doc(imageId).get();
    await storage.refFromURL(imageDoc.data()?['file_name'] as String).delete();

    // 2. Delete the main Record
    batch.delete(firestore.collection('DiagnosisRecord').doc(recordId));
    batch.delete(firestore.collection('ImageFile').doc(imageId));

    // 3. Delete linked Results and Suggestions
    // We query by record_id to find the 'sub-records' we created earlier
    final results = await firestore
        .collection('DiagnosisResult')
        .where('record_id', isEqualTo: recordId)
        .get();

    final suggestions = await firestore
        .collection('TreatmentSuggestion')
        .where('record_id', isEqualTo: recordId)
        .get();

    for (var doc in results.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in suggestions.docs) {
      batch.delete(doc.reference);
    }

    // 4. Update the Summary Count (Optional but recommended for your stats)
    DocumentReference summaryRef = firestore
        .collection('users')
        .doc(userId)
        .collection('activitySummary')
        .doc('stats');

    batch.update(summaryRef, {'totalSubmissions': FieldValue.increment(-1)});

    // Commit all deletions
    await batch.commit();
    print("Record $recordId and image deleted successfully.");
  } catch (e) {
    print("Failed to delete record: $e");
  }
}
