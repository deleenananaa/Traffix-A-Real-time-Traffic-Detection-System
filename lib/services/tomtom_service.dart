import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class TomTomService {
  static const String apiKey = 'qtP5UjXyzP4HHYqeflA7kChZ3dtZKh7W';
  static const String trafficUrl = 'https://api.tomtom.com/traffic/1';

  // Kathmandu Valley bounding box coordinates
  static const double minLat = 27.6258; // Southern boundary
  static const double maxLat = 27.8075; // Northern boundary
  static const double minLon = 85.2443; // Western boundary
  static const double maxLon = 85.5419; // Eastern boundary

  Future<List<TrafficIncident>> getTrafficIncidents() async {
    final url =
        '$trafficUrl/incidents/s0/4/bbox/$minLon,$minLat,$maxLon,$maxLat/json?key=$apiKey&language=en-GB';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final incidents = data['incidents'] as List;

        return incidents.map((incident) {
          final coordinates = incident['geometry']['coordinates'] as List;
          final properties = incident['properties'];

          return TrafficIncident(
            id: properties['id'],
            type: properties['iconCategory'] ?? 'unknown',
            severity: properties['magnitudeOfDelay'] ?? 0,
            description:
                properties['description'] ?? 'No description available',
            location: LatLng(
              coordinates[0][1] as double,
              coordinates[0][0] as double,
            ),
            roadName: properties['roadNumber'] ?? 'Unknown road',
            startTime: DateTime.parse(properties['startTime']),
            endTime:
                properties['endTime'] != null
                    ? DateTime.parse(properties['endTime'])
                    : null,
            delay: properties['delay'] ?? 0,
            length: properties['length'] ?? 0,
          );
        }).toList();
      } else {
        throw Exception(
          'Failed to load traffic incidents: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching traffic incidents: $e');
    }
  }
}

class TrafficIncident {
  final String id;
  final String type;
  final int severity;
  final String description;
  final LatLng location;
  final String roadName;
  final DateTime startTime;
  final DateTime? endTime;
  final int delay; // delay in seconds
  final int length; // length in meters

  TrafficIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.location,
    required this.roadName,
    required this.startTime,
    this.endTime,
    required this.delay,
    required this.length,
  });

  String get severityLevel {
    if (severity >= 8) return 'Severe';
    if (severity >= 4) return 'Moderate';
    return 'Minor';
  }

  Color get severityColor {
    if (severity >= 8) return Colors.red;
    if (severity >= 4) return Colors.orange;
    return Colors.yellow;
  }

  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'accident':
        return Icons.car_crash;
      case 'construction':
        return Icons.construction;
      case 'congestion':
        return Icons.traffic;
      case 'weather':
        return Icons.cloudy_snowing;
      default:
        return Icons.warning;
    }
  }
}
