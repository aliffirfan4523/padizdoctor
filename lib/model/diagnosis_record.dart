import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosisRecord {
  String id;
  String image_id;
  Timestamp timestamp;
  String user_id;
  double? latitude;
  double? longitude;
  String? locationName;

  DiagnosisRecord({
    required this.id,
    required this.image_id,
    required this.timestamp,
    required this.user_id,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'image_id': image_id,
      'timestamp': timestamp,
      'user_id': user_id,
    };
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (locationName != null) map['location_name'] = locationName;
    return map;
  }
}
