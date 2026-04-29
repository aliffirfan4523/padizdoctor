import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../model/MyActivityData.dart';
import 'package:intl/intl.dart';
import '../screens/full_map_screen.dart';

class ScanLocationsMapCard extends StatefulWidget {
  final ActivityData data;

  const ScanLocationsMapCard({
    super.key,
    required this.data,
  });

  @override
  State<ScanLocationsMapCard> createState() => _ScanLocationsMapCardState();
}

class _ScanLocationsMapCardState extends State<ScanLocationsMapCard> {
  final MapController _mapController = MapController();

  Future<void> _moveToUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    // Calculate map center from all scan locations
    double avgLat = 0, avgLng = 0;
    if (data.scanLocations.isNotEmpty) {
      for (var loc in data.scanLocations) {
        avgLat += loc.latitude;
        avgLng += loc.longitude;
      }
      avgLat /= data.scanLocations.length;
      avgLng /= data.scanLocations.length;
    } else {
      // Default center if no scans
      avgLat = 0;
      avgLng = 0;
    }

    // Group scans by approximate location for cluster counts
    final Map<String, List<ScanLocation>> clusters = {};
    for (var loc in data.scanLocations) {
      final key =
          '${loc.latitude.toStringAsFixed(3)},${loc.longitude.toStringAsFixed(3)}';
      clusters.putIfAbsent(key, () => []).add(loc);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Scan Locations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullMapScreen(data: data),
                    ),
                  );
                },
                child: Icon(Icons.open_in_full_rounded,
                    size: 16, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${clusters.length} ${clusters.length == 1 ? 'site' : 'sites'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(avgLat, avgLng),
                      initialZoom: data.scanLocations.length == 1 ? 14.0 : 10.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.padizdoctor.app',
                      ),
                      MarkerLayer(
                        markers: clusters.entries.map((entry) {
                          final locs = entry.value;
                          final first = locs.first;
                          final count = locs.length;

                          return Marker(
                            width: count > 1 ? 40 : 30,
                            height: count > 1 ? 40 : 30,
                            point: LatLng(first.latitude, first.longitude),
                            child: GestureDetector(
                              onTap: () =>
                                  _showLocationDetail(context, first, count),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.green.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: count > 1
                                      ? Text(
                                          '$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.eco,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'my_location_btn',
                      onPressed: _moveToUserLocation,
                      backgroundColor: Theme.of(context).cardColor,
                      child: Icon(Icons.my_location,
                          size: 18, color: Colors.green.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Location list summary
          ...clusters.entries.take(3).map((entry) {
            final locs = entry.value;
            final first = locs.first;
            final count = locs.length;
            final label = first.name ??
                '${first.latitude.toStringAsFixed(4)}, ${first.longitude.toStringAsFixed(4)}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? 'scan' : 'scans'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (clusters.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '+ ${clusters.length - 3} more locations',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLocationDetail(
      BuildContext context, ScanLocation location, int scanCount) {
    final dateStr = DateFormat('MMM dd, yyyy').format(location.date);
    final locationLabel = location.name ??
        '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade600, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Scan Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locationLabel,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
                '$scanCount ${scanCount == 1 ? 'scan' : 'scans'} at this location',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Last scan: $dateStr',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
