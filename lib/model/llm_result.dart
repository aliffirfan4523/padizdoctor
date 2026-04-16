import 'model.dart';

class LlmResult {
  List<BoundingBoxes> detections;
  int count;
  double processing_time_ms;
  List<ExpertAdvice> expert_advice;

  LlmResult({
    required this.detections,
    required this.count,
    required this.processing_time_ms,
    required this.expert_advice,
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
