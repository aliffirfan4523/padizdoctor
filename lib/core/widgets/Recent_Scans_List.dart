// lib/src/widgets/recent_scans_list.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/features/user/services/my_history_service.dart';
import 'package:padizdoctor/features/user/widgets/scan_card.dart';

import 'reusable_widget.dart';

class RecentScansList extends StatelessWidget {
  final String userId;
  final int? limit; // Optional: limit items for Home page

  const RecentScansList({super.key, required this.userId, this.limit});

  String _getGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDate = DateTime(date.year, date.month, date.day);

    if (scanDate == today) {
      return "Today";
    } else if (scanDate == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    } else if (scanDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return "Last 7 Days";
    } else if (scanDate.isAfter(today.subtract(const Duration(days: 30)))) {
      return "Last 30 Days";
    } else {
      return "Older";
    }
  }

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

        if (scans.isEmpty) {
          return const Center(child: Text("No recent scans available."));
        }

        // Process scans into a flat list of headers and items
        List<dynamic> items = [];
        String? currentGroup;

        for (var scan in scans) {
          final timestamp = scan['record']['timestamp'] as Timestamp?;
          if (timestamp == null) continue;

          final group = _getGroupHeader(timestamp.toDate());
          if (group != currentGroup) {
            // Omit "Today" header to blend smoothly under "Recent Scans"
            if (group != "Today") {
              items.add(group);
            }
            currentGroup = group;
          }
          items.add(scan);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(1),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            if (item is String) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            final scan = item as Map<String, dynamic>;
            final card = ScanCard(
              userId: userId,
              title: scan['disease']?['disease_name'] ??
                  scan['result']?['disease_id'] ??
                  "Healthy",
              subtitle: scan['result']['severity'] ?? "Unknown",
              recordId: scan['record_id'],
              imageId: scan['record']['image_id'],
              detail:
                  "Confidence: ${((scan['result']['confidence_score'] ?? 0) * 100).toStringAsFixed(0)}%",
              time: formatTimestamp(scan['record']['timestamp']),
              imagePath: scan['image']['file_name'] ?? "",
              statusColor: getStatusColor(scan['result']['severity']),
              statusIcon: getStatusIcon(scan['result']['severity']),
            );

            // Add margin to space out cards since we aren't using separatorBuilder anymore
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: card,
            );
          },
        );
      },
    );
  }
}
