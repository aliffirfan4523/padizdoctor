import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosisRecord {
  String id;
  String image_id;
  Timestamp timestamp;
  String user_id;

  DiagnosisRecord({
    required this.id,
    required this.image_id,
    required this.timestamp,
    required this.user_id,
  });

  Map<String, dynamic> toJson() {
    return {
      'image_id': image_id,
      'timestamp': timestamp,
      'user_id': user_id,
    };
  }
}
