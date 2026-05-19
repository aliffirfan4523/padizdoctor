class AnalysisResultsArgs {
  final String recordId;
  final String imageId;
  final String userId;
  final Map<String, dynamic>? cachedImageData;
  final Map<String, dynamic>? cachedRecordData;
  const AnalysisResultsArgs({
    required this.recordId,
    required this.imageId,
    required this.userId,
    this.cachedImageData,
    this.cachedRecordData,
  });
}
