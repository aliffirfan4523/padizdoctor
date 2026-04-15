import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

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

Future<String?> uploadInferenceImage(
    PlatformFile imageFile, String diseaseLabel) async {
  try {
    // 1. Create a unique filename
    String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$diseaseLabel.jpg';

    // 2. Point to your storage location
    Reference storageRef =
        FirebaseStorage.instance.ref().child('diagnoses/$fileName');

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
    return null;
  }
}
