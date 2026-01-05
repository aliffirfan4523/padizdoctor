// lib/src/widgets/recent_scans_list.dart
import 'package:flutter/material.dart';
import 'package:padizdoctor/src/user/my_history/my_history_service.dart';
import 'package:padizdoctor/src/user/my_history/scan_card.dart';

import 'reusable_widget.dart';

class RecentScansList extends StatelessWidget {
  final String userId;
  final int? limit; // Optional: limit items for Home page

  const RecentScansList({super.key, required this.userId, this.limit});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ScanService.getDetailedScans(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var scans = snapshot.data ?? [];
        if (limit != null && scans.length > limit!) {
          scans = scans.sublist(0, limit);
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: scans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final scan = scans[index];
            return ScanCard(
              title: scan['result']['disease_id'] == 'dis_rice_001'
                  ? "Rice Leaf Folder"
                  : "Healthy",
              subtitle: scan['result']['severity'] ?? "Unknown",
              recordId: scan['record_id'],
              imageId: scan['record']['image_id'],
              detail:
                  "Confidence: ${((scan['result']['confidence_scores'] ?? 0) * 100).toStringAsFixed(0)}%",
              time: formatTimestamp(scan['record']['timestamp']),
              imagePath: scan['image']['file_name'] ?? "",
              statusColor: getStatusColor(scan['result']['severity']),
              statusIcon: getStatusIcon(scan['result']['severity']),
              // ... pass other data as before
            );
          },
        );
      },
    );
  }
}
