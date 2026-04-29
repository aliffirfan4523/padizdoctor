import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../model/MyActivityData.dart';

class FullMapScreen extends StatefulWidget {
  final ActivityData data;

  const FullMapScreen({super.key, required this.data});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final MapController _mapController = MapController();
  late Map<String, List<ScanLocation>> _clusters;
  ScanLocation? _selectedLocation;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _processClusters();
  }

  void _processClusters() {
    _clusters = {};
    
    final filteredLocations = widget.data.scanLocations.where((loc) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Healthy') return loc.severity == 'None';
      if (_selectedFilter == 'Alerts') return loc.severity != 'None';
      return true;
    }).toList();

    for (var loc in filteredLocations) {
      final key =
          '${loc.latitude.toStringAsFixed(3)},${loc.longitude.toStringAsFixed(3)}';
      _clusters.putIfAbsent(key, () => []).add(loc);
    }
  }

  Future<void> _moveToUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate initial center
    double avgLat = 0, avgLng = 0;
    if (widget.data.scanLocations.isNotEmpty) {
      for (var loc in widget.data.scanLocations) {
        avgLat += loc.latitude;
        avgLng += loc.longitude;
      }
      avgLat /= widget.data.scanLocations.length;
      avgLng /= widget.data.scanLocations.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Scan Locations'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToUserLocation,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Healthy'),
                const SizedBox(width: 8),
                _buildFilterChip('Alerts'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(avgLat, avgLng),
              initialZoom: widget.data.scanLocations.length == 1 ? 14.0 : 8.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.padizdoctor.app',
              ),
              MarkerLayer(
                markers: _clusters.entries.map((entry) {
                  final locs = entry.value;
                  final first = locs.first;
                  final count = locs.length;

                  return Marker(
                    width: count > 1 ? 45 : 35,
                    height: count > 1 ? 45 : 35,
                    point: LatLng(first.latitude, first.longitude),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedLocation = first);
                        _mapController.move(
                            LatLng(first.latitude, first.longitude), 14.0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedLocation == first
                              ? Colors.orange.shade700
                              : Colors.green.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: count > 1
                              ? Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Icon(Icons.eco,
                                  color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Bottom Info Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _clusters.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final entry = _clusters.entries.elementAt(index);
                          final locs = entry.value;
                          final first = locs.first;
                          final count = locs.length;
                          final label = first.name ??
                              'Location ${first.latitude.toStringAsFixed(4)}, ${first.longitude.toStringAsFixed(4)}';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.location_on,
                                  color: Colors.green.shade600, size: 20),
                            ),
                            title: Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                                '$count scans • Last: ${DateFormat('MMM dd').format(first.date)}',
                                style: const TextStyle(fontSize: 12)),
                            trailing:
                                const Icon(Icons.chevron_right, size: 20),
                            onTap: () {
                              setState(() => _selectedLocation = first);
                              _mapController.move(
                                  LatLng(first.latitude, first.longitude),
                                  15.0);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
            _processClusters();
          });
        }
      },
      selectedColor: Colors.green.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade800 : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.green.shade600 : Colors.transparent,
        ),
      ),
    );
  }
}
