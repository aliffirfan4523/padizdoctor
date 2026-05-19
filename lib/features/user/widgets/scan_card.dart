import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:padizdoctor/app.dart';

import '../../../model/model.dart';

class ScanCard extends StatelessWidget {
  final String title, subtitle, detail, time;
  final String imagePath;
  final Color statusColor;
  final IconData statusIcon;
  final String recordId;
  final String imageId;
  final String userId;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapOverride;
  final Map<String, dynamic>? cachedImageData;
  final Map<String, dynamic>? cachedRecordData;

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
    required this.userId,
    this.isSelected = false,
    this.onLongPress,
    this.onTapOverride,
    this.cachedImageData,
    this.cachedRecordData,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      onTap: onTapOverride ??
          () {
            // Handle card tap if needed
            Navigator.pushNamed(
              context,
              AppRoutes.analysisResult,
              arguments: AnalysisResultsArgs(
                recordId: recordId,
                imageId: imageId,
                userId: userId,
                cachedImageData: cachedImageData,
                cachedRecordData: cachedRecordData,
              ),
            );
          },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected
                ? Colors.green
                : const Color.fromARGB(255, 127, 146, 128),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Image with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                      imageUrl: imagePath,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 24),
                      ),
                  ),
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
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  const Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
