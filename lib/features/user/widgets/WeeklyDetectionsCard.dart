import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padizdoctor/model/MyActivityData.dart';

import '../../../core/utils/format_Name.dart';

class WeeklyDetectionsCard extends StatefulWidget {
  final ActivityData data;

  const WeeklyDetectionsCard({super.key, required this.data});

  @override
  State<WeeklyDetectionsCard> createState() => _WeeklyDetectionsCardState();
}

class _WeeklyDetectionsCardState extends State<WeeklyDetectionsCard> {
  bool isWeeklyView = true;

  Map<String, List<int>> _getDiseaseTrends() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map<String, List<int>> trends = {};

    for (var scan in widget.data.scans) {
      final timestamp = scan['record']['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      final date = timestamp.toDate();
      final scanDay = DateTime(date.year, date.month, date.day);
      final diffDays = today.difference(scanDay).inDays;

      final diseaseName = scan['disease']?['disease_name'] ??
          formatName(scan['result']?['disease_id'] ?? "Healthy");

      if (!trends.containsKey(diseaseName)) {
        trends[diseaseName] = List.filled(isWeeklyView ? 7 : 4, 0);
      }

      if (isWeeklyView) {
        if (diffDays >= 0 && diffDays < 7) {
          // Map weekday 1=Mon, 7=Sun to index 0=Mon, 6=Sun
          trends[diseaseName]![date.weekday - 1]++;
        }
      } else {
        if (diffDays >= 0 && diffDays < 28) {
          int weekIndex = 3 - (diffDays ~/ 7);
          trends[diseaseName]![weekIndex]++;
        }
      }
    }
    return trends;
  }

  final List<Color> diseaseColors = [
    Colors.green,
    Colors.redAccent,
    Colors.orange,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final diseaseTrends = _getDiseaseTrends();
    final diseaseNames = diseaseTrends.keys.toList();

    // Calculate MaxY across all trends
    double maxVal = 0;
    for (var trend in diseaseTrends.values) {
      for (var val in trend) {
        if (val > maxVal) maxVal = val.toDouble();
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Detections',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor == Colors.white
                      ? Colors.grey.shade200
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => isWeeklyView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isWeeklyView
                              ? Theme.of(context).cardColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isWeeklyView
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          'Week',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isWeeklyView
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isWeeklyView
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isWeeklyView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isWeeklyView
                              ? Theme.of(context).cardColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !isWeeklyView
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          'Month',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !isWeeklyView
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: !isWeeklyView
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.8,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final diseaseName = diseaseNames[spot.barIndex];
                        return LineTooltipItem(
                          '$diseaseName: ${spot.y.toInt()}',
                          TextStyle(
                            color: diseaseColors[
                                spot.barIndex % diseaseColors.length],
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxVal > 5 ? (maxVal / 5).ceil().toDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (isWeeklyView) {
                          const days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          if (value < 0 || value >= days.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          );
                        } else {
                          const weeks = ['W1', 'W2', 'W3', 'W4'];
                          if (value < 0 || value >= weeks.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              weeks[value.toInt()],
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxVal > 5 ? (maxVal / 5).ceil().toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: isWeeklyView ? 6 : 3,
                minY: 0,
                maxY: maxVal + 1,
                lineBarsData: List.generate(diseaseNames.length, (index) {
                  final diseaseName = diseaseNames[index];
                  final trend = diseaseTrends[diseaseName]!;
                  final color = diseaseColors[index % diseaseColors.length];

                  return LineChartBarData(
                    spots: List.generate(
                      trend.length,
                      (i) => FlSpot(i.toDouble(), trend[i].toDouble()),
                    ),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(diseaseNames.length, (index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: diseaseColors[index % diseaseColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    diseaseNames[index],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
