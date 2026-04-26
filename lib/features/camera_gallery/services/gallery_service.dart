import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../../../model/model.dart';

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

  // Add user_id for backend LLM logging (TC-TPS-006)
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    request.fields['user_id'] = user.uid;
  }

  // Eagerly read bytes before building the request.
  // MultipartFile.fromPath() opens the file lazily when the request is sent,
  // which can fail if the file_picker cache file was evicted by Android.
  final Uint8List imageBytes;
  if (imageFile.bytes != null) {
    imageBytes = imageFile.bytes!;
  } else if (imageFile.path != null) {
    final file = File(imageFile.path!);
    if (!await file.exists()) {
      throw Exception(
          'Image file no longer exists at path: ${imageFile.path}. Try picking the image again.');
    }
    imageBytes = await file.readAsBytes();
  } else {
    throw Exception('Invalid image file: no path or bytes available.');
  }

  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: imageFile.name,
      contentType: http.MediaType('image', extension),
    ),
  );

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    // Cloudflare returns 5xx for tunnel offline
    if (response.statusCode >= 500) {
      throw Exception('NETWORK_ERROR: Server returned ${response.statusCode}');
    }

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

    // Generic failure (404, etc.)
    throw Exception("Inference failed with status: ${response.statusCode}");
  } catch (e) {
    if (e is FormatException || e.toString().contains('NETWORK_ERROR')) {
      throw Exception('NETWORK_ERROR: $e');
    }
    rethrow;
  }
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

/// Saves inference results to Firestore and returns the [recordId] (nowId)
/// so callers can navigate directly to the results screen.
Future<String> addInferenceResultToHistory(
    LlmResult llmResult, PlatformFile imageFile) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return "";
  try {
    llmResult.detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    // When no disease is detected, detections is empty — use 'Healthy' as label.
    final String primaryDiseaseId = llmResult.detections.isEmpty
        ? 'Healthy'
        : llmResult.detections.first.label;

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
      width: llmResult.original_width,
      height: llmResult.original_height,
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
      String subId = "${nowId}_${advice.status}";

      // For Healthy results, detections is empty so specificBoxes will be [].
      List<BoundingBoxes> specificBoxes = llmResult.detections.where((box) {
        return box.label.toLowerCase().replaceAll('_', '') ==
            advice.diseaseName.toLowerCase().replaceAll('_', '');
      }).toList();

      final bestDet = llmResult.detections.isEmpty
          ? null
          : llmResult.detections.firstWhere(
              (d) => d.label == advice.diseaseName,
              orElse: () => llmResult.detections.first,
            );

      DiagnosisResult result = DiagnosisResult(
        id: subId,
        record_id: record.id,
        disease_id: advice.diseaseName, // 'Healthy' for Healthy scans
        confidence_score: advice.diseaseName == 'Healthy'
            ? 1.0
            : (bestDet?.confidence ?? 0.0),
        severity: advice.severity,
        bounding_boxes: specificBoxes,
      );

      TreatmentSuggestion suggestion = TreatmentSuggestion(
        id: subId,
        record_id: record.id,
        source: advice.source,
        text: advice.treatment,
        type: 'LLM_ANALYSIS',
      );

      batch.set(
          FirebaseFirestore.instance.collection('DiagnosisResult').doc(subId),
          result.toJson());
      batch.set(
          FirebaseFirestore.instance
              .collection('TreatmentSuggestion')
              .doc(subId),
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
    print("Saving inference result to history — recordId: $nowId");
    return nowId;
  } catch (e) {
    print("Firebase Write Error: $e");
    throw Exception("Failed to save inference result: $e");
  }
}

Future<String> uploadInferenceImage(
    PlatformFile imageFile, String diseaseLabel) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    // 1. Create a unique filename
    String fileName =
        '${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // 2. Point to your storage location
    Reference storageRef =
        FirebaseStorage.instance.ref().child('diagnosis_images/$fileName');

    // 3. Handle both Web (bytes) and Mobile (path)
    UploadTask uploadTask;
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    // Always use putData() to avoid PathNotFound errors.
    // file_picker caches files in a temp dir that Android can evict by the
    // time Firebase tries to stat the file. Reading bytes eagerly prevents
    // the race condition, regardless of whether we have a path or raw bytes.
    final Uint8List imageBytes;
    if (imageFile.bytes != null) {
      imageBytes = imageFile.bytes!;
    } else if (imageFile.path != null) {
      final file = File(imageFile.path!);
      if (!await file.exists()) {
        throw Exception(
            'Image file no longer exists at path: ${imageFile.path}');
      }
      imageBytes = await file.readAsBytes();
    } else {
      throw Exception('No image data available (path and bytes are both null)');
    }
    uploadTask = storageRef.putData(imageBytes, metadata);

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
