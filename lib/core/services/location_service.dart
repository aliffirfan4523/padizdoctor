import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Provides device GPS location and reverse geocoding via OpenStreetMap
/// Nominatim API (free, no API key required).
class LocationService {
  /// Returns the current GPS position, or null if permission is denied
  /// or location services are disabled. Never throws — failures are silent
  /// so scans can proceed without location.
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // LocationService: Failed to get position
      return null;
    }
  }

  /// Reverse geocodes [latitude]/[longitude] to a human-readable place name
  /// using OpenStreetMap Nominatim (free, no API key).
  /// Returns null on failure.
  static Future<String?> reverseGeocode(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$latitude&lon=$longitude&format=json&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'PadizDoctor/1.0',
        'Accept-Language': 'en',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address == null) return data['display_name'];

        // Build a concise location string from available address components
        final parts = <String>[];

        // Village/town/city
        final locality = address['village'] ??
            address['town'] ??
            address['city'] ??
            address['suburb'];
        if (locality != null) parts.add(locality);

        // State/district
        final region =
            address['state_district'] ?? address['state'] ?? address['county'];
        if (region != null) parts.add(region);

        if (parts.isEmpty) {
          return data['display_name'];
        }
        return parts.join(', ');
      }
    } catch (e) {
      // LocationService: Reverse geocoding failed
    }
    return null;
  }
}
