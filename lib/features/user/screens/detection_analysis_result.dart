import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padizdoctor/core/utils/bounding_box.dart';

import '../../../model/model.dart';
import '../services/my_history_service.dart';

import '../widgets/widgets.dart';

class AnalysisResultsScreen extends StatefulWidget {
  final String recordId;
  final String imageId;
  final String userId;

  const AnalysisResultsScreen({
    super.key,
    required this.recordId,
    required this.imageId,
    required this.userId,
  });

  @override
  State<AnalysisResultsScreen> createState() => _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState extends State<AnalysisResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analysis Results",
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Implement delete functionality
              try {
                deleteDiagnosisRecord(
                    widget.recordId, widget.userId, widget.imageId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Record deleted successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete record")),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchFullAnalysisData(widget.recordId, widget.imageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error loading analysis results"));
          }

          final data = snapshot.data!;
          print(data['results']);
          final List<dynamic> resultsList = data['results'];
          final Map<String, dynamic> diseasesMap = data['diseases'];
          final image = data['image'];
          final record = data['record'];
          final List<dynamic> allSuggestions = data['suggestions'];

          // 1. Aggregate ALL bounding boxes from ALL results
          final List<BoundingBoxes> allDetections = [];
          for (var result in resultsList) {
            final boxes = (result['bounding_boxes'] as List).map((box) {
              double x1 = box['x1']?.toDouble() ?? 0.0;
              double y1 = box['y1']?.toDouble() ?? 0.0;
              double x2 = box['x2']?.toDouble() ?? 0.0;
              double y2 = box['y2']?.toDouble() ?? 0.0;

              return BoundingBoxes(
                confidence: box['confidence']?.toDouble() ?? 0.0,
                label: box['label'] ?? 'unknown',
                x1: x1,
                y1: y1,
                x2: x2,
                y2: y2,
                width: (x2 - x1).toDouble(),
                height: (y2 - y1).toDouble(),
              );
            }).toList();
            allDetections.addAll(boxes);
          }

          return DefaultTabController(
            length: resultsList.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Builder(builder: (context) {
                          final tabController =
                              DefaultTabController.of(context);
                          return AnimatedBuilder(
                            animation: tabController,
                            builder: (context, _) {
                              final activeIndex = tabController.index;
                              final activeResult =
                                  resultsList[activeIndex] as Map;
                              return DetectionHeader(
                                imageUrl: image['file_name'],
                                detections: allDetections,
                                activeLabel: activeResult['disease_id'],
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 20),
                        Builder(builder: (context) {
                          DateTime scanDate = DateTime.now();
                          if (record != null && record['timestamp'] != null) {
                            if (record['timestamp'] is Timestamp) {
                              scanDate =
                                  (record['timestamp'] as Timestamp).toDate();
                            } else if (record['timestamp'] is String) {
                              scanDate =
                                  DateTime.tryParse(record['timestamp']) ??
                                      DateTime.now();
                            }
                          }
                          final dateStr = DateFormat('MMM dd, yyyy • hh:mm a')
                              .format(scanDate);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  "Scanned on $dateStr",
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverAppBarDelegate(
                    TabBar(
                      isScrollable: resultsList.length > 2,
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                      tabs: resultsList.map((res) {
                        final result = Map<String, dynamic>.from(res);
                        final disease =
                            _resolveDisease(result['disease_id'], diseasesMap);
                        return Tab(
                          text: disease['disease_name'] ?? 'Unknown',
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: resultsList.map((res) {
                  final result = Map<String, dynamic>.from(res);
                  final disease =
                      _resolveDisease(result['disease_id'], diseasesMap);
                  final resultId = result['id'];
                  final diseaseSuggestions = allSuggestions
                      .where((sug) => sug['id'] == resultId)
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDiseaseDetails(result, disease),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          "AI Recommendations",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (diseaseSuggestions.isEmpty)
                          const Text(
                              "No specific AI recommendations found for this detection.")
                        else
                          ...diseaseSuggestions
                              .map((sug) => buildSuggestionCard(sug))
                              .toList(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Returns a resolved disease map. When [diseaseId] is 'Healthy' or not
  /// found in [diseasesMap], a friendly synthetic map is returned so the
  /// UI never shows 'Unknown Disease' for a Healthy scan.
  static Map<String, dynamic> _resolveDisease(
      String? diseaseId, Map<String, dynamic> diseasesMap) {
    if (diseaseId == 'Healthy' || diseaseId == null) {
      return {
        'disease_name': 'Healthy Crop',
        'description': 'No diseases were detected in this scan. '
            'Your paddy crop appears to be in good health.',
      };
    }
    final found = diseasesMap[diseaseId];
    if (found != null) return Map<String, dynamic>.from(found);
    // Unknown disease ID — return a generic fallback.
    return {'disease_name': diseaseId, 'description': 'No details available.'};
  }

  Widget _buildDiseaseDetails(
      Map<String, dynamic> result, Map<String, dynamic> disease) {
    final String name = disease['disease_name'] ?? 'Healthy Crop';
    final String severity = result['severity'] ?? 'None';
    final double confidence =
        (result['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final String description =
        disease['description'] ?? 'No description available.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitleSection(name, severity),
        const SizedBox(height: 16),
        buildConfidenceScore(confidence),
        const SizedBox(height: 24),
        buildInfoSection(
          name == 'Healthy Crop' ? 'Crop Health Status' : 'About the Disease',
          description,
        ),
      ],
    );
  }
}
