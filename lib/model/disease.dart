import 'dart:ui';

class Disease {
  String id;
  String disease_name;
  String description;

  Disease({
    required this.id,
    required this.disease_name,
    required this.description,
  });
}

class Detection {
  final String label;
  final double confidence;
  final Rect bbox;

  Detection({
    required this.label,
    required this.confidence,
    required this.bbox,
  });
}
