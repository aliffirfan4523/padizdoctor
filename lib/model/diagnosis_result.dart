class DiagnosisResult {
  String id;
  List<BoundingBoxes> bounding_boxes;
  double confidence_score;
  String disease_id;
  String record_id;
  String severity;

  DiagnosisResult({
    required this.id,
    required this.bounding_boxes,
    required this.confidence_score,
    required this.disease_id,
    required this.record_id,
    required this.severity,
  });
}

class BoundingBoxes {
  String label;
  double x;
  double y;
  double width;
  double height;

  BoundingBoxes({
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
