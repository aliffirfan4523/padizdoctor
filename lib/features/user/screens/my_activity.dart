import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padizdoctor/features/user/screens/detection_analysis_result.dart';
import 'package:padizdoctor/features/user/services/my_history_service.dart';
import 'package:padizdoctor/features/user/services/report_service.dart';
import 'package:padizdoctor/features/user/widgets/widgets.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padizdoctor/features/camera_gallery/screens/gallery.dart';

import '../../../core/utils/format_Name.dart';
import '../../../model/MyActivityData.dart';

class MyActivity extends StatefulWidget {
  const MyActivity({super.key});

  @override
  State<MyActivity> createState() => _MyActivityState();
}

class _MyActivityState extends State<MyActivity> {
  final List<Color> chartColors = [
    Colors.green,
    Colors.redAccent,
    Colors.orange,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.teal,
  ];

  ActivityData _processData(
      List<Map<String, dynamic>> scans, DocumentSnapshot? statsDoc) {
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
          formatName(scan['result']?['disease_id'] ?? "Healthy");

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
          severity: severity ?? 'N/A',
          diseaseName: diseaseName,
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
        final totalMs =
            (statsMap['totalProcessingTime'] as num?)?.toDouble() ?? 0.0;
        final totalSubs =
            (statsMap['totalSubmissions'] as num?)?.toDouble() ?? 0.0;
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
      scans: scans,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activitySummary')
          .doc('stats')
          .snapshots(),
      builder: (context, statsSnapshot) {
        final statsDoc = statsSnapshot.data;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: ScanService.getDetailedScans(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final scans = snapshot.data ?? [];
            final data = _processData(scans, statsDoc);

            return Scaffold(
              floatingActionButton: scans.isEmpty
                  ? null
                  : FloatingActionButton(
                      onPressed: () => _generateReport(context, data),
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.download_rounded,
                          color: Colors.black87),
                    ),
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Firebase streams auto-update, but we add a small delay
                    // to give the user satisfying visual feedback that a refresh occurred.
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: scans.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: EmptyActivityState(
                                onScanPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final userId = FirebaseAuth.instance.currentUser?.uid;
                                  final hasSeenCameraInstructions =
                                      prefs.getBool('hasSeenCameraInstructions_$userId') ?? false;

                                  if (hasSeenCameraInstructions) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const GalleryPicker()),
                                    );
                                  } else {
                                    _showCameraInstructions(context);
                                  }
                                },
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ActivityHeader(
                                data: data,
                                onCalendarTap: (context, data) =>
                                    _showCalendar(context, data),
                              ),
                              const SizedBox(height: 24),
                              _buildTopStatCards(data),
                              const SizedBox(height: 16),
                              WeeklyDetectionsCard(data: data),
                              const SizedBox(height: 16),
                              DiseaseDistributionCard(
                                data: data,
                                chartColors: chartColors,
                              ),
                              if (data.scanLocations.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ScanLocationsMapCard(
                                  data: data,
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _generateReport(BuildContext context, ActivityData data) {
    final progressNotifier = ValueNotifier<String>('Preparing report...');
    bool cancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ValueListenableBuilder<String>(
              valueListenable: progressNotifier,
              builder: (_, message, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Compiling Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      cancelled = true;
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    ReportService.generateAndDownloadReport(
      data,
      onProgress: (msg) {
        if (!cancelled) progressNotifier.value = msg;
      },
    ).then((_) {
      if (!cancelled && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }).catchError((e) {
      if (!cancelled && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (!cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    });
  }

  void _showCalendar(BuildContext context, ActivityData data) {
    DateTime selectedDay = DateTime.now();
    DateTime focusedDay = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
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
                    focusedDay: focusedDay,
                    selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setDialogState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });

                      // Filter scans for the selected date
                      final filteredScans = data.scans.where((scan) {
                        final timestamp =
                            scan['record']['timestamp'] as Timestamp?;
                        if (timestamp == null) return false;
                        return isSameDay(timestamp.toDate(), selectedDay);
                      }).toList();

                      if (filteredScans.isNotEmpty) {
                        Navigator.pop(context);
                        _showReportsForDate(
                            context, selectedDay, filteredScans);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'No scans found for ${DateFormat('MMM dd, yyyy').format(selectedDay)}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
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
        });
      },
    );
  }

  void _showReportsForDate(BuildContext context, DateTime date,
      List<Map<String, dynamic>> filteredScans) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports for ${DateFormat('MMMM dd').format(date)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${filteredScans.length} scans found',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredScans.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final scan = filteredScans[index];
                    final diseaseName = scan['disease']?['disease_name'] ??
                        formatName(scan['result']?['disease_id'] ?? "Healthy");
                    final severity =
                        scan['result']['severity'] as String? ?? 'N/A';
                    final timestamp = scan['record']['timestamp'] as Timestamp;
                    final timeStr =
                        DateFormat('hh:mm a').format(timestamp.toDate());
                    final imageUrl = scan['image']['file_name'] as String?;

                    Color severityColor = Colors.green;
                    if (severity == 'Moderate') severityColor = Colors.orange;
                    if (severity == 'High') severityColor = Colors.red;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalysisResultsScreen(
                              recordId: scan['record_id'],
                              imageId: scan['record']['image_id'],
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              cachedImageData: scan['image'],
                              cachedRecordData: scan['record'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                            Icons.image_not_supported,
                                            size: 20),
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, size: 20),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatName(diseaseName),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: severityColor.withValues(
                                              alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          severity,
                                          style: TextStyle(
                                            color: severityColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStatCards(ActivityData data) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: "HEALTHY",
            countStr: NumberFormat.decimalPattern().format(data.healthyCount),
            trend: data.healthyTrend,
            icon: Icons.check_circle,
            color: Colors.green,
            bgColor: Colors.green.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            title: "ALERTS",
            countStr: NumberFormat.decimalPattern().format(data.alertsCount),
            trend: data.alertsTrend,
            icon: Icons.warning_rounded,
            color: Colors.redAccent,
            bgColor: Colors.redAccent.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            title: "AVG TIME",
            countStr: data.avgTimeStr,
            trend: 0,
            icon: Icons.timer,
            color: Colors.blueAccent,
            bgColor: Colors.blueAccent.withValues(alpha: 0.1),
            showTrend: false,
          ),
        ),
      ],
    );
  }

  void _showCameraInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "How to take a good scan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const ListTile(
                leading: Icon(Icons.wb_sunny, color: Colors.orange),
                title: Text("Ensure good lighting"),
                subtitle: Text("Take the photo in daylight or well-lit area."),
              ),
              const ListTile(
                leading: Icon(Icons.center_focus_strong, color: Colors.blue),
                title: Text("Keep the leaf in focus"),
                subtitle: Text(
                    "Make sure the affected area is clear and not blurry."),
              ),
              const ListTile(
                leading: Icon(Icons.filter_center_focus, color: Colors.green),
                title: Text("Center the disease"),
                subtitle: Text(
                    "Position the diseased part of the leaf in the middle of the frame."),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  await prefs.setBool(
                      'hasSeenCameraInstructions_$userId', true);

                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GalleryPicker()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B9D4A),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("I Understand, Proceed",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
