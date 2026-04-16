import 'package:cloud_firestore/cloud_firestore.dart';

class ImageFile {
  String id;
  String file_name;
  String format;
  double size_mb;
  Timestamp uploaded_at;

  ImageFile({
    required this.id,
    required this.file_name,
    required this.format,
    required this.size_mb,
    required this.uploaded_at,
  });

  Map<String, dynamic> toJson() {
    return {
      'file_name': file_name,
      'format': format,
      'size_mb': size_mb,
      'uploaded_at': uploaded_at,
    };
  }
}
