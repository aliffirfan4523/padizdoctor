// lib/src/widgets/recent_scans_list.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/features/user/services/my_history_service.dart';
import 'package:padizdoctor/features/user/widgets/scan_card.dart';

import '../utils/format_Name.dart';
import 'reusable_widget.dart';

class RecentScansList extends StatefulWidget {
  final String userId;
  final int? limit;
  final String searchQuery;
  final String filter;
  final bool isSelectable;
  final Map<String, String> selectedRecords; // recordId -> imageId
  final void Function(String recordId, String imageId)? onSelectionChanged;
  final void Function(String recordId, String imageId)? onLongPress;

  const RecentScansList({
    super.key,
    required this.userId,
    this.limit,
    this.searchQuery = "",
    this.filter = "All",
    this.isSelectable = false,
    this.selectedRecords = const {},
    this.onSelectionChanged,
    this.onLongPress,
  });

  @override
  State<RecentScansList> createState() => _RecentScansListState();
}

class _RecentScansListState extends State<RecentScansList> {
  late Stream<List<Map<String, dynamic>>> _scansStream;

  @override
  void initState() {
    super.initState();
    _scansStream = ScanService.getDetailedScans(widget.userId);
  }

  @override
  void didUpdateWidget(RecentScansList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _scansStream = ScanService.getDetailedScans(widget.userId);
    }
  }

  String _getGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDate = DateTime(date.year, date.month, date.day);

    if (scanDate == today) return "Today";
    if (scanDate == today.subtract(const Duration(days: 1))) return "Yesterday";
    if (scanDate.isAfter(today.subtract(const Duration(days: 7))))
      return "Last 7 Days";
    if (scanDate.isAfter(today.subtract(const Duration(days: 30))))
      return "Last 30 Days";
    return "Older";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _scansStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        var scans = snapshot.data ?? [];

        // Apply Search Query
        if (widget.searchQuery.isNotEmpty) {
          scans = scans.where((scan) {
            final diseaseName = (scan['disease']?['disease_name'] ??
                    scan['result']?['disease_id'] ??
                    "Healthy")
                .toString()
                .toLowerCase();
            return diseaseName.contains(widget.searchQuery.toLowerCase());
          }).toList();
        }

        // Apply Filter
        if (widget.filter != "All") {
          scans = scans.where((scan) {
            final severity = scan['result']?['severity']?.toString() ?? "None";
            if (widget.filter == "Healthy")
              return severity == "None" || severity == "Healthy";
            if (widget.filter == "Alerts")
              return severity != "None" && severity != "Healthy";
            return true;
          }).toList();
        }

        if (widget.limit != null && scans.length > widget.limit!) {
          scans = scans.sublist(0, widget.limit);
        }

        if (scans.isEmpty) {
          return _buildEmptyState();
        }

        List<dynamic> items = [];
        String? currentGroup;

        for (var scan in scans) {
          final timestamp = scan['record']['timestamp'] as Timestamp?;
          if (timestamp == null) continue;

          final group = _getGroupHeader(timestamp.toDate());
          if (group != currentGroup) {
            if (group != "Today" || widget.limit != null) {
              items.add(group);
            }
            currentGroup = group;
          }
          items.add(scan);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            if (item is String) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              );
            }

            final scan = item as Map<String, dynamic>;
            final recordId = scan['record_id'];
            final imageId = scan['record']['image_id'];
            final isSelected = widget.selectedRecords.containsKey(recordId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ScanCard(
                userId: widget.userId,
                title: scan['disease']?['disease_name']?.toString() ??
                    (scan['result']?['disease_id'] != null
                        ? formatName(scan['result']!['disease_id'].toString())
                        : "Healthy"),
                subtitle: scan['result']?['severity']?.toString() ?? "Unknown",
                recordId: recordId?.toString() ?? "",
                imageId: imageId?.toString() ?? "",
                detail:
                    "Confidence: ${((scan['result']['confidence_score'] ?? 0) * 100).toStringAsFixed(0)}%",
                time: formatTimestamp(scan['record']['timestamp']),
                imagePath: scan['image']['file_name'] ?? "",
                statusColor: getStatusColor(scan['result']['severity']),
                statusIcon: getStatusIcon(scan['result']['severity']),
                isSelected: isSelected,
                onLongPress: widget.onLongPress != null
                    ? () => widget.onLongPress!(recordId, imageId)
                    : null,
                onTapOverride: widget.isSelectable
                    ? () => widget.onSelectionChanged?.call(recordId, imageId)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Unable to load scans",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your connection.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              "No scans found",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try adjusting your filters or search query.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
