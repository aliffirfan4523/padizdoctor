import 'package:flutter/material.dart';

import '../screens/detection_analysis_result.dart';

class ScanCard extends StatelessWidget {
  final String title, subtitle, detail, time;
  final String imagePath;
  final Color statusColor;
  final IconData statusIcon;
  final String recordId;
  final String imageId;

  const ScanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.time,
    required this.imagePath,
    required this.statusColor,
    required this.statusIcon,
    required this.recordId,
    required this.imageId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Handle card tap if needed
        Navigator.push(context, MaterialPageRoute(builder: (_) {
          return AnalysisResultsScreen(
            recordId: recordId,
            imageId: imageId,
          );
        }));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Slightly lighter navy
          border: Border.all(color: const Color.fromARGB(31, 75, 75, 75)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Image with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imagePath,
                      width: 64, height: 64, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Info text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.w500)),
                  Text(detail, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            // Time and Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
