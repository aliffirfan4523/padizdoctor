import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../../../model/model.dart';

//https://padizdoctor-backend-production.up.railway.app/check-blur/
Future<Map<String, dynamic>> checkImageBlur(PlatformFile imageFile) async {
  final uri = Uri.parse(
    'https://api.padizdoctor.me/check-blur/',
  );

  final request = http.MultipartRequest('POST', uri);

  if (imageFile.path != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path!,
      ),
    );
  } else if (imageFile.bytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageFile.bytes!,
        filename: imageFile.name,
      ),
    );
  } else {
    throw Exception("Invalid image file");
  }

  final response = await request.send();
  final body = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    return json.decode(body);
  } else {
    throw Exception("Blur check failed: $body");
  }
}

Future<Map<String, dynamic>> inferenceImage(PlatformFile imageFile) async {
  final uri = Uri.parse(
    'https://api.padizdoctor.me/detect',
  );
  final String extension = imageFile.extension ?? 'jpg';
  final request = http.MultipartRequest('POST', uri);

  if (imageFile.path != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path!,
        // THIS IS THE KEY FIX:
        contentType: http.MediaType('image', extension),
      ),
    );
  } else if (imageFile.bytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageFile.bytes!,
        filename: imageFile.name,
        // AND HERE FOR BYTES:
        contentType: http.MediaType('image', extension),
      ),
    );
  } else {
    throw Exception("Invalid image file");
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  print('Response Status: ${response.statusCode}');
  print('Response Body: ${response.body}');

  final decodedData = json.decode(response.body);

  if (response.statusCode == 200) {
    return decodedData;
  }
  if (response.statusCode == 422) {
    String errorMessage = decodedData['detail'] ?? "Validation error";

    if (errorMessage == "BLURRY_IMAGE") {
      throw Exception(
          "The image is too blurry. Please try again with better lighting.");
    }
    throw Exception(errorMessage);
  }

  // Generic failure (500, 404, etc.)
  throw Exception("Inference failed with status: ${response.statusCode}");
}

Future<PlatformFile> pickPaddyImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
  );

  try {
    if (result != null) {
      String? filepath = result.files.single.path;

      if (filepath != null) {
        PlatformFile file = result.files.single;
        return file;
      } else {
        return Future.error('File path is null');
      }
    }
  } catch (e) {
    rethrow;
  }
  throw Exception('No file was picked');
}

Future<void> addInferenceResultToHistory(
    LlmResult llmResult, PlatformFile imageFile) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  llmResult.detections.sort((a, b) => b.confidence.compareTo(a.confidence));

  final primaryDetection = llmResult.detections.first;
  final String primaryDiseaseId = primaryDetection.label;

  DocumentReference summaryRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('activitySummary')
      .doc('stats'); // Using a fixed ID 'stats' makes it easy to update

  String fileName = await uploadInferenceImage(imageFile, primaryDiseaseId);

  final String nowId = DateTime.now().millisecondsSinceEpoch.toString();
  final Timestamp nowTs = Timestamp.now();

  // Reference the sub-models you defined in your screenshot
  final batch = FirebaseFirestore.instance.batch();

  ImageFile img = ImageFile(
    id: nowId,
    file_name: fileName,
    format: imageFile.extension ?? 'jpg',
    size_mb: (imageFile.size / (1024 * 1024)).toDouble(),
    uploaded_at: Timestamp.now(),
  );
  DiagnosisRecord record = DiagnosisRecord(
    id: nowId,
    image_id: img.id,
    timestamp: nowTs,
    user_id: user!.uid, // Replace with actual user ID
  );

  print("--- STARTING DEEP DEBUG ---");
  print(
      "ADVICE LIST: ${llmResult.expert_advice.map((e) => e.diseaseName).toList()}");
  print(
      "YOLO LABELS FOUND: ${llmResult.detections.map((d) => d.label).toList()}");

  for (var advice in llmResult.expert_advice) {
    // Generate a unique ID for this specific finding
    print("Attempting match for: ${advice.diseaseName}");
    String subId = "${nowId}_${advice.status}";

    List<BoundingBoxes> specificBoxes = llmResult.detections.where((box) {
      // Use the 'fuzzy match' to be safe
      return box.label.toLowerCase().replaceAll('_', '') ==
          advice.diseaseName.toLowerCase().replaceAll('_', '');
    }).toList();

    // --- THE TEST PRINT ---
    print("TESTING JSON FOR: ${advice.diseaseName}");
    print(specificBoxes.map((e) => e.toJson()).toList());
    if (specificBoxes.isEmpty) {
      print(
          "❌ ERROR: specificBoxes is empty for ${advice.diseaseName}. Check your .where() condition!");
    } else {
      print(
          "✅ SUCCESS: Found ${specificBoxes.length} boxes for ${advice.diseaseName}.");
    }
// ----------------------

    // Find the best detection for this specific disease to get confidence
    final bestDet = llmResult.detections.firstWhere(
      (d) => d.label == advice.diseaseName,
      orElse: () => llmResult.detections.first,
    );

    /*DocumentSnapshot diseaseDoc = await FirebaseFirestore.instance
      .collection('Disease')
      .doc(bestDet.label)
      .get();
    */
    // Create DiagnosisResult using your class
    DiagnosisResult result = DiagnosisResult(
      id: subId,
      record_id: record.id, // IMPORTANT: Link back to the main record
      disease_id:
          advice.diseaseName, // Assuming label corresponds to disease_id
      confidence_score: bestDet.confidence,
      severity: advice.severity,
      bounding_boxes: specificBoxes,
    );

    // Create TreatmentSuggestion using your class
    TreatmentSuggestion suggestion = TreatmentSuggestion(
      id: subId,
      record_id: record.id,
      source: advice.source,
      text: advice.treatment,
      type: 'LLM_ANALYSIS',
    );

    // Add to batch using .toJson()
    batch.set(
        FirebaseFirestore.instance.collection('DiagnosisResult').doc(subId),
        result.toJson());
    batch.set(
        FirebaseFirestore.instance.collection('TreatmentSuggestion').doc(subId),
        suggestion.toJson());
  }

  batch.set(
    FirebaseFirestore.instance.collection('ImageFile').doc(nowId),
    img.toJson(), // Direct passing
  );
  batch.set(
    FirebaseFirestore.instance.collection('DiagnosisRecord').doc(nowId),
    record.toJson(), // Direct passing
  );

  batch.set(
      summaryRef,
      {
        'totalSubmissions': FieldValue.increment(1),
        'lastUpdated': Timestamp.now(),
        'userId': user.uid,
        // Optional: If you want to track total time to calculate average later
        'totalProcessingTime':
            FieldValue.increment(llmResult.processing_time_ms ?? 0),
      },
      SetOptions(merge: true));

  await batch.commit();

  print("Saving inference result to history: $llmResult");
}

Future<String> uploadInferenceImage(
    PlatformFile imageFile, String diseaseLabel) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    // 1. Create a unique filename
    String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$diseaseLabel.jpg';

    // 2. Point to your storage location
    Reference storageRef = FirebaseStorage.instance.ref().child(
        'diagnosis_images/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

    // 3. Handle both Web (bytes) and Mobile (path)
    UploadTask uploadTask;
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    if (imageFile.path != null) {
      uploadTask = storageRef.putFile(File(imageFile.path!), metadata);
    } else {
      uploadTask = storageRef.putData(imageFile.bytes!, metadata);
    }

    // 4. Wait for completion and get the URL
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    print("Image uploaded successfully: $downloadUrl");
    return downloadUrl;
  } catch (e) {
    print("Firebase Upload Error: $e");
    throw Exception("Failed to upload image");
  }
}
