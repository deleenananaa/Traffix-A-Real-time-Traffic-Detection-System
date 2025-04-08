import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class TrafficData {
  final LatLng location;
  final double density; // 0-1 scale where 1 is highest density
  final String congestionLevel; // 'low', 'medium', 'high'
  final DateTime timestamp;

  TrafficData({
    required this.location,
    required this.density,
    required this.congestionLevel,
    required this.timestamp,
  });

  factory TrafficData.fromJson(Map<String, dynamic> json) {
    return TrafficData(
      location: LatLng(json['latitude'], json['longitude']),
      density: json['density'].toDouble(),
      congestionLevel: json['congestion_level'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'density': density,
      'congestion_level': congestionLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TrafficIncident {
  final String id;
  final LatLng location;
  final String type; // 'accident', 'construction', 'roadblock', etc.
  final String description;
  final DateTime reportTime;
  final String status; // 'active', 'resolved'
  final String reportedBy; // user ID or 'system'

  TrafficIncident({
    required this.id,
    required this.location,
    required this.type,
    required this.description,
    required this.reportTime,
    required this.status,
    required this.reportedBy,
  });

  factory TrafficIncident.fromJson(Map<String, dynamic> json) {
    return TrafficIncident(
      id: json['id'],
      location: LatLng(json['latitude'], json['longitude']),
      type: json['type'],
      description: json['description'],
      reportTime: DateTime.parse(json['report_time']),
      status: json['status'],
      reportedBy: json['reported_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type,
      'description': description,
      'report_time': reportTime.toIso8601String(),
      'status': status,
      'reported_by': reportedBy,
    };
  }
}

class TrafficService {
  static final TrafficService _instance = TrafficService._internal();
  final _database = FirebaseDatabase.instance.ref();
  final _trafficRef = FirebaseDatabase.instance.ref('traffic');
  final _incidentsRef = FirebaseDatabase.instance.ref('incidents');

  // Stream controllers for real-time updates
  final _trafficDataController =
      StreamController<List<TrafficData>>.broadcast();
  final _incidentsController =
      StreamController<List<TrafficIncident>>.broadcast();

  // Cached data
  List<TrafficData> _cachedTrafficData = [];
  List<TrafficIncident> _cachedIncidents = [];

  factory TrafficService() {
    return _instance;
  }

  TrafficService._internal() {
    // Initialize listeners
    _initializeTrafficDataListener();
    _initializeIncidentsListener();
  }

  void _initializeTrafficDataListener() {
    _trafficRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      _cachedTrafficData =
          data.entries.map((e) {
            final value = e.value as Map<dynamic, dynamic>;
            return TrafficData(
              location: LatLng(
                value['latitude'] as double,
                value['longitude'] as double,
              ),
              density: value['density'] as double,
              congestionLevel: value['congestion_level'] as String,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                value['timestamp'] as int,
              ),
            );
          }).toList();
      _trafficDataController.add(_cachedTrafficData);
    });
  }

  void _initializeIncidentsListener() {
    _incidentsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      _cachedIncidents =
          data.entries.map((e) {
            final value = e.value as Map<dynamic, dynamic>;
            return TrafficIncident(
              id: e.key,
              location: LatLng(
                value['latitude'] as double,
                value['longitude'] as double,
              ),
              type: value['type'] as String,
              description: value['description'] as String,
              reportTime: DateTime.fromMillisecondsSinceEpoch(
                value['reportTime'] as int,
              ),
              status: value['status'] as String,
              reportedBy: value['reportedBy'] as String,
            );
          }).toList();
      _incidentsController.add(_cachedIncidents);
    });
  }

  // Get traffic data stream
  Stream<List<TrafficData>> get trafficDataStream =>
      _trafficDataController.stream;

  // Get incidents stream
  Stream<List<TrafficIncident>> get incidentsStream =>
      _incidentsController.stream;

  // Report new traffic incident
  Future<void> reportIncident(TrafficIncident incident) async {
    await _incidentsRef.push().set(incident.toJson());
  }

  // Update traffic data
  Future<void> updateTrafficData(TrafficData data) async {
    final key = '${data.location.latitude}_${data.location.longitude}';
    await _database.child('traffic_data').child(key).set(data.toJson());
  }

  // Calculate traffic density for a specific area
  double calculateTrafficDensity(List<TrafficData> dataPoints) {
    if (dataPoints.isEmpty) return 0.0;
    return dataPoints.map((d) => d.density).reduce((a, b) => a + b) /
        dataPoints.length;
  }

  // Get congestion level based on density
  String getCongestionLevel(double density) {
    if (density < 0.3) return 'low';
    if (density < 0.7) return 'medium';
    return 'high';
  }

  // Get color for visualization based on congestion level
  Color getTrafficColor(String congestionLevel) {
    switch (congestionLevel) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get nearby incidents
  List<TrafficIncident> getNearbyIncidents(LatLng location, double radiusKm) {
    return _cachedIncidents.where((incident) {
      final distance = const Distance().as(
        LengthUnit.Kilometer,
        location,
        incident.location,
      );
      return distance <= radiusKm;
    }).toList();
  }

  // Get traffic data for a specific area
  List<TrafficData> getAreaTrafficData(LatLng center, double radiusKm) {
    return _cachedTrafficData.where((data) {
      final distance = const Distance().as(
        LengthUnit.Kilometer,
        center,
        data.location,
      );
      return distance <= radiusKm;
    }).toList();
  }

  void dispose() {
    _trafficDataController.close();
    _incidentsController.close();
  }
}
