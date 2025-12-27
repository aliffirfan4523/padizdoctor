import 'dart:ui';

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
