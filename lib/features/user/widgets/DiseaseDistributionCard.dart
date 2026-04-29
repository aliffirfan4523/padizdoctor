import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../model/MyActivityData.dart';

class DiseaseDistributionCard extends StatefulWidget {
  final ActivityData data;
  final List<Color> chartColors;

  const DiseaseDistributionCard({
    super.key,
    required this.data,
    required this.chartColors,
  });

  @override
  State<DiseaseDistributionCard> createState() =>
      _DiseaseDistributionCardState();
}

class _DiseaseDistributionCardState extends State<DiseaseDistributionCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.totalScans == 0) return const SizedBox.shrink();

    // Sort diseases by count descending
    final sortedEntries = widget.data.diseaseDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare pie chart sections
    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = widget.chartColors[i % widget.chartColors.length];
      final percentage = (entry.value / widget.data.totalScans) * 100;
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
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
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
                            widget.data.totalScans.toString(),
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
