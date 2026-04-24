import 'model.dart';

class LlmResult {
  List<BoundingBoxes> detections;
  int count;
  double processing_time_ms;
  int original_width;
  int original_height;
  List<ExpertAdvice> expert_advice;

  LlmResult({
    required this.detections,
    required this.count,
    required this.processing_time_ms,
    required this.expert_advice,
    required this.original_width,
    required this.original_height,
  });
}

class ExpertAdvice {
  String diseaseName;
  String status;
  String severity;
  String treatment;
  String symptoms;
  String source;

  ExpertAdvice({
    required this.diseaseName,
    required this.status,
    required this.severity,
    required this.treatment,
    required this.symptoms,
    required this.source,
  });
}
