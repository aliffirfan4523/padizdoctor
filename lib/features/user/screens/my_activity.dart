import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
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

  ActivityData _processData(List<Map<String, dynamic>> scans, DocumentSnapshot? statsDoc) {
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
    List<ScanLocation> scanLocations = [];

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

      // Extract location data if available
      final lat = scan['record']['latitude'] as num?;
      final lng = scan['record']['longitude'] as num?;
      if (lat != null && lng != null) {
        scanLocations.add(ScanLocation(
          latitude: lat.toDouble(),
          longitude: lng.toDouble(),
          name: scan['record']['location_name'] as String?,
          date: date,
        ));
      }

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

    String avgTimeStr = "0.0s";
    if (statsDoc != null && statsDoc.exists) {
      final statsMap = statsDoc.data() as Map<String, dynamic>?;
      if (statsMap != null) {
        final totalMs = (statsMap['totalProcessingTime'] as num?)?.toDouble() ?? 0.0;
        final totalSubs = (statsMap['totalSubmissions'] as num?)?.toDouble() ?? 0.0;
        if (totalSubs > 0) {
          avgTimeStr = (totalMs / totalSubs / 1000.0).toStringAsFixed(1) + "s";
        }
      }
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
      avgTimeStr: avgTimeStr,
      scanLocations: scanLocations,
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('activitySummary').doc('stats').snapshots(),
          builder: (context, statsSnapshot) {
            final statsDoc = statsSnapshot.data;
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: ScanService.getDetailedScans(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final scans = snapshot.data ?? [];
                final data = _processData(scans, statsDoc);

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
                      if (data.scanLocations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildScanLocationsMapCard(data),
                      ],
                    ],
                  ),
                );
              },
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
            countStr: NumberFormat.decimalPattern().format(data.healthyCount),
            trend: data.healthyTrend,
            icon: Icons.check_circle,
            color: Colors.green,
            bgColor: Colors.green.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: "ALERTS",
            countStr: NumberFormat.decimalPattern().format(data.alertsCount),
            trend: data.alertsTrend,
            icon: Icons.warning_rounded,
            color: Colors.redAccent,
            bgColor: Colors.redAccent.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: "AVG TIME",
            countStr: data.avgTimeStr,
            trend: 0,
            icon: Icons.timer,
            color: Colors.blueAccent,
            bgColor: Colors.blueAccent.withOpacity(0.1),
            showTrend: false,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String countStr,
    required double trend,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool showTrend = true,
  }) {
    final isPositive = trend >= 0;
    final trendStr = '${isPositive ? '+' : ''}${trend.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(12),
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
                countStr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showTrend)
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
                      const SizedBox(width: 2),
                      Text(
                        trendStr,
                        style: TextStyle(
                          fontSize: 10,
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

  // ── Scan Locations Map Card ──────────────────────────────────────────────
  Widget _buildScanLocationsMapCard(ActivityData data) {
    // Calculate map center from all scan locations
    double avgLat = 0, avgLng = 0;
    for (var loc in data.scanLocations) {
      avgLat += loc.latitude;
      avgLng += loc.longitude;
    }
    avgLat /= data.scanLocations.length;
    avgLng /= data.scanLocations.length;

    // Group scans by approximate location for cluster counts
    final Map<String, List<ScanLocation>> clusters = {};
    for (var loc in data.scanLocations) {
      // Round to ~100m precision for clustering
      final key = '${loc.latitude.toStringAsFixed(3)},${loc.longitude.toStringAsFixed(3)}';
      clusters.putIfAbsent(key, () => []).add(loc);
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
          Row(
            children: [
              const Text(
                'Scan Locations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${clusters.length} ${clusters.length == 1 ? 'site' : 'sites'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(avgLat, avgLng),
                  initialZoom: data.scanLocations.length == 1 ? 14.0 : 10.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.padizdoctor.app',
                  ),
                  MarkerLayer(
                    markers: clusters.entries.map((entry) {
                      final locs = entry.value;
                      final first = locs.first;
                      final count = locs.length;

                      return Marker(
                        width: count > 1 ? 40 : 30,
                        height: count > 1 ? 40 : 30,
                        point:
                            LatLng(first.latitude, first.longitude),
                        child: GestureDetector(
                          onTap: () => _showLocationDetail(
                              context, first, count),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: count > 1
                                  ? Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.eco,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Location list summary
          ...clusters.entries.take(3).map((entry) {
            final locs = entry.value;
            final first = locs.first;
            final count = locs.length;
            final label = first.name ??
                '${first.latitude.toStringAsFixed(4)}, ${first.longitude.toStringAsFixed(4)}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? 'scan' : 'scans'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (clusters.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '+ ${clusters.length - 3} more locations',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLocationDetail(
      BuildContext context, ScanLocation location, int scanCount) {
    final dateStr = DateFormat('MMM dd, yyyy').format(location.date);
    final locationLabel = location.name ??
        '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade600, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Scan Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locationLabel,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('$scanCount ${scanCount == 1 ? 'scan' : 'scans'} at this location',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Last scan: $dateStr',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
