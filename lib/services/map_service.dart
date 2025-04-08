import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapService {
  static const String osrmBaseUrl = 'router.project-osrm.org';
  static const String nominatimBaseUrl = 'nominatim.openstreetmap.org';

  // Get TileLayer for the map
  static String getTileLayer() {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  // Default map options for Kathmandu
  static MapOptions get defaultMapOptions => MapOptions(
    initialCenter: const LatLng(27.7172, 85.3240), // Kathmandu coordinates
    initialZoom: 13.0,
    maxZoom: 19.0,
    minZoom: 3.0,
    keepAlive: true,
  );

  // Search locations using Nominatim
  static Future<List<SearchResult>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.https(nominatimBaseUrl, '/search', {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '5',
      'viewbox':
          '85.2443,27.8075,85.5419,27.6258', // Kathmandu Valley bounding box
      'bounded': '1',
      'countrycodes': 'np',
    });

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Traffix/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((result) {
          return SearchResult(
            name: result['display_name'] ?? '',
            address: result['display_name'] ?? '',
            position: LatLng(
              double.parse(result['lat']),
              double.parse(result['lon']),
            ),
          );
        }).toList();
      }
      throw Exception('Failed to load search results: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error searching location: $e');
    }
  }

  // Get route using OSRM
  static Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    final coordinates =
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

    final uri = Uri.https(osrmBaseUrl, '/route/v1/driving/$coordinates', {
      'overview': 'full',
      'alternatives': 'false',
      'steps': 'true',
      'annotations': 'true',
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final duration = route['duration'];
          final distance = route['distance'];

          // Decode polyline
          final List<LatLng> points = _decodePolyline(geometry);

          return RouteResult(
            points: points,
            summary:
                '${formatDistance(distance.round())} - ${formatDuration(duration.round())}',
            lengthInMeters: distance.round(),
            travelTimeInSeconds: duration.round(),
          );
        }
      }
      throw Exception('Failed to calculate route: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting route: $e');
    }
  }

  // Helper function to decode polyline
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  static String formatDuration(int seconds) {
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    } else if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      return '$minutes min';
    }
    return '$seconds sec';
  }

  static String formatDistance(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  // Get current location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // Stream location updates
  static Stream<Position> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}

class SearchResult {
  final String name;
  final String address;
  final LatLng position;

  SearchResult({
    required this.name,
    required this.address,
    required this.position,
  });
}

class RouteResult {
  final List<LatLng> points;
  final String summary;
  final int lengthInMeters;
  final int travelTimeInSeconds;

  RouteResult({
    required this.points,
    required this.summary,
    required this.lengthInMeters,
    required this.travelTimeInSeconds,
  });
}
