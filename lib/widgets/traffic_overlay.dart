import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:latlong2/latlong.dart';
import '../services/traffic_service.dart';

class TrafficOverlay extends StatelessWidget {
  final List<TrafficData> trafficData;
  final List<TrafficIncident> incidents;
  final Function(TrafficIncident) onIncidentTap;

  const TrafficOverlay({
    super.key,
    required this.trafficData,
    required this.incidents,
    required this.onIncidentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Traffic density visualization
        PolylineLayer(polylines: _createTrafficPolylines()),
        // Traffic incidents markers
        MarkerLayer(markers: _createIncidentMarkers()),
      ],
    );
  }

  List<Polyline> _createTrafficPolylines() {
    List<Polyline> polylines = [];

    // Group nearby traffic data points
    Map<String, List<TrafficData>> segments = {};
    for (var data in trafficData) {
      String key =
          '${(data.location.latitude * 100).round()}_${(data.location.longitude * 100).round()}';
      segments.putIfAbsent(key, () => []).add(data);
    }

    // Create polylines for each segment
    segments.forEach((_, dataPoints) {
      if (dataPoints.length >= 2) {
        double avgDensity = TrafficService().calculateTrafficDensity(
          dataPoints,
        );
        String congestionLevel = TrafficService().getCongestionLevel(
          avgDensity,
        );
        Color color = TrafficService().getTrafficColor(congestionLevel);

        polylines.add(
          Polyline(
            points: dataPoints.map((data) => data.location).toList(),
            strokeWidth: 4.0,
            color: color.withValues(alpha: 0.7),
          ),
        );
      }
    });

    return polylines;
  }

  List<Marker> _createIncidentMarkers() {
    return incidents.map((incident) {
      IconData iconData;
      Color iconColor;

      // Choose icon based on incident type
      switch (incident.type.toLowerCase()) {
        case 'accident':
          iconData = Icons.car_crash;
          iconColor = Colors.red;
          break;
        case 'construction':
          iconData = Icons.construction;
          iconColor = Colors.orange;
          break;
        case 'roadblock':
          iconData = Icons.block;
          iconColor = Colors.red;
          break;
        default:
          iconData = Icons.warning;
          iconColor = Colors.yellow;
      }

      return Marker(
        point: incident.location,
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () => onIncidentTap(incident),
          child: Icon(iconData, color: iconColor, size: 30),
        ),
      );
    }).toList();
  }
}
