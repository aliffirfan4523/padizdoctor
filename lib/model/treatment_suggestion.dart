class TreatmentSuggestion {
  String id;
  String record_id;
  String source;
  String text;
  String type;

  TreatmentSuggestion({
    required this.id,
    required this.record_id,
    required this.source,
    required this.text,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': record_id,
      'source': source,
      'text': text,
      'type': type,
    };
  }
}
