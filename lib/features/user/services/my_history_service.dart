import 'package:cloud_firestore/cloud_firestore.dart';
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
          (img, res) => {
            'record': recordData,
            'record_id': doc.id,
            'image': img.data() ?? {},
            'result': res.docs.isNotEmpty ? res.docs.first.data() : {},
          },
        );
      }).toList();
      return CombineLatestStream.list(streams);
    });
  }
}

// Logic to join the 4 collections needed for this screen
Future<Map<String, dynamic>> fetchFullAnalysisData(
    String recordId, String imageId) async {
  final db = FirebaseFirestore.instance;

  try {
    // 1. Get the Result first to find the disease_id
    final resultSnap = await db
        .collection('DiagnosisResult')
        .where('record_id', isEqualTo: recordId)
        .limit(1)
        .get();

    if (resultSnap.docs.isEmpty) {
      // Debug: Print the ID you are looking for to compare with Firestore console
      print("DEBUG: No DiagnosisResult found for record_id: $recordId");
      throw "DiagnosisResult missing";
    }
    final resultData = resultSnap.docs.first.data();

    // 2. Fetch linked data in parallel: Image, Disease info, and AI Suggestions
    final snapshots = await Future.wait([
      db.collection('ImageFile').doc(imageId).get(),
      db.collection('Disease').doc(resultData['disease_id']).get(),
      db
          .collection('TreatmentSuggestion') // Targeted collection
          .where('record_id', isEqualTo: recordId)
          .get(),
    ]);

    final imageDoc = snapshots[0] as DocumentSnapshot;
    final diseaseDoc = snapshots[1] as DocumentSnapshot;
    final suggestionSnap = snapshots[2] as QuerySnapshot;

    if (!imageDoc.exists) throw "Image document not found in ImageFile";
    if (!diseaseDoc.exists)
      throw "Disease info not found for ${resultData['disease_id']}";

    return {
      'result': resultData,
      'image': imageDoc.data(),
      'disease': diseaseDoc.data(),
      // Map the list of suggestions from the TreatmentSuggestion collection
      'suggestions': suggestionSnap.docs.map((doc) => doc.data()).toList(),
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
