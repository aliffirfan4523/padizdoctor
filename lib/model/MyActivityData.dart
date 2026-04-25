class ActivityData {
  final int healthyCount;
  final int alertsCount;
  final double healthyTrend;
  final double alertsTrend;
  final List<int> weeklyDetections; // Mon (0) to Sun (6)
  final List<int> monthlyDetections; // 4 weeks of the month
  final Map<String, int> diseaseDistribution;
  final Map<DateTime, int> scansByDate;
  final int totalScans;

  ActivityData({
    required this.healthyCount,
    required this.alertsCount,
    required this.healthyTrend,
    required this.alertsTrend,
    required this.weeklyDetections,
    required this.monthlyDetections,
    required this.diseaseDistribution,
    required this.scansByDate,
    required this.totalScans,
  });
}
