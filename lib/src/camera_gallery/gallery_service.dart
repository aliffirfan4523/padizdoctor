import 'dart:convert';

import 'package:file_picker/file_picker.dart';
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

  final response = await request.send();
  final body = await response.stream.bytesToString();
  print('Response Status: ${response.statusCode}');
  print('Response Body: $body');
  if (response.statusCode == 200) {
    return json.decode(body);
  } else {
    throw Exception("Inference failed: $body");
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
