import 'package:flutter/material.dart';
import 'package:padizdoctor/core/utils/bounding_box.dart';

import '../../../model/model.dart';
import '../services/my_history_service.dart'; // Ensure Detection class is here

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
          final result = data['result'];
          final image = data['image'];
          final disease = data['disease'];

          // Map Firestore boxes to your Detection model
          final List<BoundingBoxes> detections =
              (result['bounding_boxes'] as List).map((box) {
            // Pull values directly as doubles
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
              // Calculate width/height from the flat numbers
              width: (x2 - x1).toDouble(),
              height: (y2 - y1).toDouble(),
            );
          }).toList();
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  DetectionHeader(
                    imageUrl: image['file_name'],
                    detections: detections,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Disease Title and Risk Badge
                        _buildTitleSection(
                            disease['disease_name'], result['severity']),

                        const SizedBox(height: 16),

                        // 3. Confidence Match Bar
                        _buildConfidenceScore(result['confidence_score']),

                        const SizedBox(height: 24),

                        // 4. About Disease Section
                        _buildInfoSection(
                            "About the Disease", disease['description']),

                        const SizedBox(height: 24),

                        // Display suggestions from the TreatmentSuggestion collection
                        if ((data['suggestions'] as List).isEmpty)
                          const Text(
                              "No specific AI recommendations found for this scan.")
                        else
                          ...data['suggestions']
                              .map((sug) => _buildSuggestionCard(sug))
                              .toList(),

                        // 5. Recommended Actions (Treatment Catalog)
                        //_buildTreatmentList(treatments),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(String name, String severity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(name,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            severity.toUpperCase(),
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceScore(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Confidence Match",
                style: TextStyle(fontWeight: FontWeight.w500)),
            Text("${(score * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score,
          backgroundColor: Colors.grey[200],
          color: Colors.green,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(color: Colors.grey[700], height: 1.5)),
      ],
    );
  }

  Widget _buildTreatmentList(List<dynamic> treatments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: treatments
            .map((tx) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(tx['treatment_text']),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> sug) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sug['type'] ?? 'AI Suggestion', // e.g., 'LLM' or 'RuleBased'
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  sug['text'] ?? '',
                  style: TextStyle(color: Colors.grey[800], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void getImageSize(String url, void Function(Size size) onResult) {
  final image = Image.network(url);
  final ImageStream stream = image.image.resolve(const ImageConfiguration());

  stream.addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      final mySize =
          Size(info.image.width.toDouble(), info.image.height.toDouble());
      onResult(mySize);
    }),
  );
}

// 1. Convert your helper to a proper Widget that handles its own state
class DetectionHeader extends StatefulWidget {
  final String imageUrl;
  final List<BoundingBoxes> detections;

  const DetectionHeader(
      {super.key, required this.imageUrl, required this.detections});

  @override
  State<DetectionHeader> createState() => _DetectionHeaderState();
}

class _DetectionHeaderState extends State<DetectionHeader> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final ImageStream stream = Image.network(widget.imageUrl)
        .image
        .resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _imageSize =
              Size(info.image.width.toDouble(), info.image.height.toDouble());
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_imageSize == null)
      return const Center(child: CircularProgressIndicator());

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: AspectRatio(
        aspectRatio: _imageSize!.width / _imageSize!.height,
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              // Use fit: BoxFit.fill to ensure the coordinates map 1:1 to the widget size
              Image.network(
                widget.imageUrl,
                fit: BoxFit.fill,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: BoundingBoxPainter(
                  widget.detections,
                  const Size(768, 768), // Your YOLO model input size
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
