import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/model/MyActivityData.dart';

class WeeklyDetectionsCard extends StatefulWidget {
  final ActivityData data;

  const WeeklyDetectionsCard({super.key, required this.data});

  @override
  State<WeeklyDetectionsCard> createState() => _WeeklyDetectionsCardState();
}

class _WeeklyDetectionsCardState extends State<WeeklyDetectionsCard> {
  bool isWeeklyView = true;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

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
                lineTouchData: LineTouchData(enabled: true),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
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
                maxY: (isWeeklyView
                            ? data.weeklyDetections
                            : data.monthlyDetections)
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble() +
                    2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      isWeeklyView ? 7 : 4,
                      (i) => FlSpot(
                        i.toDouble(),
                        (isWeeklyView
                                ? data.weeklyDetections[i]
                                : data.monthlyDetections[i])
                            .toDouble(),
                      ),
                    ),
                    isCurved: true,
                    color: Colors.green.shade400,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.shade400.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
