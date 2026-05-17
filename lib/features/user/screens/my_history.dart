import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/core/widgets/Recent_Scans_List.dart';
import 'package:padizdoctor/model/model.dart';
import 'package:padizdoctor/features/user/services/my_history_service.dart';

import '../../../core/widgets/reusable_header.dart';

class MyHistory extends StatefulWidget {
  MyHistory({super.key, required this.currentUserId});
  final String currentUserId;
  @override
  State<MyHistory> createState() => _MyHistoryState();
}

class _MyHistoryState extends State<MyHistory> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All";
  bool _isSelectionMode = false;
  Map<String, String> _selectedRecords = {};
  bool _isDeleting = false;

  void _toggleSelection(String recordId, String imageId) {
    setState(() {
      if (_selectedRecords.containsKey(recordId)) {
        _selectedRecords.remove(recordId);
        if (_selectedRecords.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedRecords[recordId] = imageId;
      }
    });
  }

  void _enterSelectionMode(String recordId, String imageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedRecords[recordId] = imageId;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRecords.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedRecords.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Scans"),
        content: Text("Are you sure you want to delete ${_selectedRecords.length} scans?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      for (final entry in _selectedRecords.entries) {
        await deleteDiagnosisRecord(entry.key, widget.currentUserId, entry.value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete scans: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        _exitSelectionMode();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Beautiful Header
          SliverAppBar(
            expandedHeight: _isSelectionMode ? 60 : 160,
            floating: false,
            pinned: true,
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _exitSelectionMode,
                  )
                : null,
            actions: _isSelectionMode
                ? [
                    _isDeleting
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: _deleteSelected,
                          ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _isSelectionMode ? '${_selectedRecords.length} Selected' : 'History',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              titlePadding: _isSelectionMode
                  ? const EdgeInsets.only(bottom: 16)
                  : const EdgeInsets.only(bottom: 100),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade500,
                    ],
                  ),
                ),
              ),
            ),
            bottom: _isSelectionMode
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(100),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search scan results...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Filter Chips
                    Row(
                      children: [
                        _buildFilterChip("All"),
                        const SizedBox(width: 8),
                        _buildFilterChip("Alerts"),
                        const SizedBox(width: 8),
                        _buildFilterChip("Healthy"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Scan List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RecentScansList(
                  userId: widget.currentUserId,
                  searchQuery: _searchQuery,
                  filter: _selectedFilter,
                  isSelectable: _isSelectionMode,
                  selectedRecords: _selectedRecords,
                  onSelectionChanged: _toggleSelection,
                  onLongPress: _enterSelectionMode,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
