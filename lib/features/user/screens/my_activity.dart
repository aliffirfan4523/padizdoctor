import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padizdoctor/features/user/widgets/WeeklyDetectionsCard.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:padizdoctor/features/user/services/my_history_service.dart';

import '../../../model/MyActivityData.dart';

class MyActivity extends StatefulWidget {
  const MyActivity({super.key});

  @override
  State<MyActivity> createState() => _MyActivityState();
}

class _MyActivityState extends State<MyActivity> {
  int touchedIndex = -1;

  final List<Color> chartColors = [
    Colors.green,
    Colors.redAccent,
    Colors.orange,
    Colors.blueAccent,
    Colors.purpleAccent,
  ];

  ActivityData _processData(List<Map<String, dynamic>> scans) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int healthyCount = 0;
    int alertsCount = 0;

    int healthyCurrent7 = 0;
    int healthyPrev7 = 0;

    int alertsCurrent7 = 0;
    int alertsPrev7 = 0;

    List<int> weeklyDetections = List.filled(7, 0); // Mon to Sun
    List<int> monthlyDetections = List.filled(4, 0); // Week 1 to Week 4
    Map<String, int> distribution = {};
    Map<DateTime, int> scansByDate = {};

    for (var scan in scans) {
      final timestamp = scan['record']['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      final date = timestamp.toDate();
      final scanDay = DateTime(date.year, date.month, date.day);
      final diffDays = today.difference(scanDay).inDays;

      final severity = scan['result']['severity'] as String?;
      final isHealthy = severity == 'None';
      final diseaseName = scan['disease']?['disease_name'] ??
          scan['result']?['disease_id'] ??
          "Healthy";

      // All time counts
      if (isHealthy) {
        healthyCount++;
      } else {
        alertsCount++;
      }

      distribution[diseaseName] = (distribution[diseaseName] ?? 0) + 1;
      scansByDate[scanDay] = (scansByDate[scanDay] ?? 0) + 1;

      // Trend calculations
      if (diffDays >= 0 && diffDays < 7) {
        if (isHealthy) {
          healthyCurrent7++;
        } else {
          alertsCurrent7++;
        }
        // Map weekday 1=Mon, 7=Sun to index 0=Mon, 6=Sun
        weeklyDetections[date.weekday - 1]++;
      } else if (diffDays >= 7 && diffDays < 14) {
        if (isHealthy) {
          healthyPrev7++;
        } else {
          alertsPrev7++;
        }
      }

      if (diffDays >= 0 && diffDays < 28) {
        int weekIndex = 3 - (diffDays ~/ 7);
        monthlyDetections[weekIndex]++;
      }
    }

    double calculateTrend(int current, int previous) {
      if (previous == 0) return current > 0 ? 100.0 : 0.0;
      return ((current - previous) / previous) * 100;
    }

    return ActivityData(
      healthyCount: healthyCount,
      alertsCount: alertsCount,
      healthyTrend: calculateTrend(healthyCurrent7, healthyPrev7),
      alertsTrend: calculateTrend(alertsCurrent7, alertsPrev7),
      weeklyDetections: weeklyDetections,
      monthlyDetections: monthlyDetections,
      diseaseDistribution: distribution,
      scansByDate: scansByDate,
      totalScans: scans.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        child: const Icon(Icons.download_rounded, color: Colors.black87),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: ScanService.getDetailedScans(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final scans = snapshot.data ?? [];
            final data = _processData(scans);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, data),
                  const SizedBox(height: 24),
                  _buildTopStatCards(data),
                  const SizedBox(height: 16),
                  WeeklyDetectionsCard(data: data),
                  const SizedBox(height: 16),
                  _buildDiseaseDistributionCard(data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ActivityData data) {
    final now = DateTime.now();
    final monthYear = DateFormat('MMM yyyy').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trend Reports',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'User Overview • $monthYear',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: IconButton(
                icon: const Icon(Icons.calendar_today, size: 20),
                onPressed: () {
                  _showCalendar(context, data);
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune, size: 20),
                onPressed: () {},
              ),
            ),
          ],
        )
      ],
    );
  }

  void _showCalendar(BuildContext context, ActivityData data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: DateTime.now(),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final normalizedDate =
                          DateTime(date.year, date.month, date.day);
                      final count = data.scansByDate[normalizedDate] ?? 0;
                      if (count == 0) return const SizedBox.shrink();

                      // Vary intensity/size based on scan count
                      double size = 6.0;
                      Color color = Colors.green.shade400;
                      if (count >= 2 && count < 5) {
                        size = 8.0;
                        color = Colors.green.shade600;
                      } else if (count >= 5) {
                        size = 10.0;
                        color = Colors.green.shade800;
                      }

                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopStatCards(ActivityData data) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "HEALTHY",
            count: data.healthyCount,
            trend: data.healthyTrend,
            icon: Icons.check_circle,
            color: Colors.green,
            bgColor: Colors.green.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: "ALERTS",
            count: data.alertsCount,
            trend: data.alertsTrend,
            icon: Icons.warning_rounded,
            color: Colors.redAccent,
            bgColor: Colors.redAccent.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required int count,
    required double trend,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final isPositive = trend >= 0;
    final trendStr = '${isPositive ? '+' : ''}${trend.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumberFormat.decimalPattern().format(count),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDiseaseDistributionCard(ActivityData data) {
    if (data.totalScans == 0) return const SizedBox.shrink();

    // Sort diseases by count descending
    final sortedEntries = data.diseaseDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare pie chart sections
    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = chartColors[i % chartColors.length];
      final percentage = (entry.value / data.totalScans) * 100;
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 45.0 : 40.0;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '', // We use legend instead of titles on pie
          radius: radius,
        ),
      );

      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disease Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections: sections,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.totalScans.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: legendItems,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
