import 'dart:ui';

import 'model.dart';

class Disease {
  String id;
  String disease_name;
  String description;

  Disease({
    required this.id,
    required this.disease_name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'disease_name': disease_name,
      'description': description,
    };
  }
}
