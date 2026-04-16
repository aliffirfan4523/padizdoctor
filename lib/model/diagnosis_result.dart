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

  // Inside DiagnosisResult class
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_id': record_id,
      'disease_id': disease_id,
      'confidence_score': confidence_score,
      'severity': severity,
      'bounding_boxes': bounding_boxes
          .map((box) => {
                'label': box.label,
                'x1': box.x1,
                'y1': box.y1,
                'x2': box.x2,
                'y2': box.y2,
                'width': box.width,
                'height': box.height,
                'confidence': box.confidence, // This will now definitely save
              })
          .toList(),
    };
  }
}

class BoundingBoxes {
  String label;
  double x1;
  double x2;
  double y1;
  double y2;
  double width;
  double height;
  final double confidence;

  BoundingBoxes({
    required this.label,
    required this.x1,
    required this.x2,
    required this.y1,
    required this.y2,
    required this.width,
    required this.height,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'x1': x1,
        'x2': x2,
        'y1': y1,
        'y2': y2,
        'width': width,
        'height': height,
        'confidence': confidence,
      };
}
