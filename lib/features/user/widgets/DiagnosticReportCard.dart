import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padizdoctor/core/utils/bounding_box.dart';
import 'package:padizdoctor/model/diagnosis_result.dart';

class DiagnosticReportCard extends StatelessWidget {
  final Map<String, dynamic> image;
  final Map<String, dynamic> record;
  final List<dynamic> results;
  final Map<String, dynamic> diseases;
  final List<dynamic> allSuggestions;
  final List<BoundingBoxes> detections;
  final String? activeLabel;

  const DiagnosticReportCard({
    super.key,
    required this.image,
    required this.record,
    required this.results,
    required this.diseases,
    required this.allSuggestions,
    required this.detections,
    this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime date = record['timestamp'] is DateTime
        ? record['timestamp']
        : (record['timestamp'] as dynamic)?.toDate() ?? DateTime.now();

    final String formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(date);

    return Container(
      width: 800, // Further increased width for maximum clarity
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grass, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PadizDoctor",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Diagnosis Report",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                formattedDate.split('•')[0],
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Image with Bounding Boxes
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: image['file_name'] ?? '',
                      fit: BoxFit.cover,
                      maxWidthDiskCache: 2000,
                      memCacheWidth: 2000,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BoundingBoxPainter(
                        detections,
                        Size(
                          (image['width'] as num?)?.toDouble() ?? 1000.0,
                          (image['height'] as num?)?.toDouble() ?? 1000.0,
                        ),
                        activeLabel: activeLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Detailed Findings for each disease
          const Text(
            "Diagnostic Findings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),

          ...results.map((res) {
            final resultId = res['id'];
            final diseaseId = res['disease_id'];
            final disease = diseases[diseaseId] ??
                {
                  'disease_name': diseaseId ?? 'Unknown',
                  'description': 'No details available.'
                };

            final String diseaseName = disease['disease_name'] ?? 'Unknown';
            final String description =
                disease['description'] ?? 'No details available.';
            final String severity = res['severity'] ?? 'N/A';
            final double confidence =
                (res['confidence_score'] as num?)?.toDouble() ?? 0.0;
            final suggestions =
                allSuggestions.where((s) => s['id'] == resultId).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diseaseName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoBadge("Severity: $severity", Colors.orange),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                          "${(confidence * 100).toStringAsFixed(1)}% Confidence",
                          Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    "Recommended Treatments",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (suggestions.isEmpty)
                    Text("No specific recommendations found.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12))
                  else
                    ...suggestions.map((sug) {
                      final String fullText = sug['text'] ?? '';
                      final String type = sug['type'] ?? 'AI Suggestion';

                      String? organicText;
                      String? chemicalText;
                      String? otherText;

                      final organicMatch = RegExp(
                              r"Organic:\s*(.*?)(?=Chemical:|$)",
                              caseSensitive: false,
                              dotAll: true)
                          .firstMatch(fullText);
                      final chemicalMatch = RegExp(r"Chemical:\s*(.*)",
                              caseSensitive: false, dotAll: true)
                          .firstMatch(fullText);

                      if (organicMatch != null || chemicalMatch != null) {
                        organicText = organicMatch?.group(1)?.trim();
                        chemicalText = chemicalMatch?.group(1)?.trim();
                      } else {
                        otherText = fullText.trim();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (organicText != null && organicText.isNotEmpty)
                            _buildReportMethodSection(
                              "Organic Method",
                              organicText,
                              Icons.nature_outlined,
                              Colors.green,
                            ),
                          if (organicText != null &&
                              organicText.isNotEmpty &&
                              chemicalText != null &&
                              chemicalText.isNotEmpty)
                            const SizedBox(height: 12),
                          if (chemicalText != null && chemicalText.isNotEmpty)
                            _buildReportMethodSection(
                              "Chemical Method",
                              chemicalText,
                              Icons.science_outlined,
                              Colors.blue,
                            ),
                          if (otherText != null && otherText.isNotEmpty)
                            _buildReportMethodSection(
                              type,
                              otherText,
                              Icons.auto_awesome,
                              Colors.green,
                            ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                ],
              ),
            );
          }).toList(),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Scanned with PadizDoctor.me",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportMethodSection(
      String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[800],
            height: 1.5,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
