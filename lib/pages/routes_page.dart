import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong;
import '../services/map_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:routing_client_dart/routing_client_dart.dart' as routing;
import 'dart:math';
import 'package:logger/logger.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final _logger = Logger();
  // Add this variable to track selected index
  int _selectedIndex = 1;
  final flutter_map.MapController _mapController = flutter_map.MapController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  latlong.LatLng? _currentLocation;
  latlong.LatLng? _startLocation;
  latlong.LatLng? _endLocation;
  List<SearchResult> _startSearchResults = [];
  List<SearchResult> _endSearchResults = [];
  RouteResult? _routeResult;
  bool _isLoading = false;
  Timer? _startDebounce;
  Timer? _endDebounce;
  StreamSubscription<Position>? _locationSubscription;
  final manager = routing.RoutingManager();

  // Add these new state variables
  bool _isNavigating = false;
  List<routing.RouteInstruction>? _instructions;
  int _currentInstructionIndex = 0;
  Timer? _navigationTimer;
  routing.Route? _currentRoad;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupSearchListeners();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startDebounce?.cancel();
    _endDebounce?.cancel();
    _locationSubscription?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await MapService.getCurrentLocation();
      setState(() {
        _currentLocation = latlong.LatLng(
          position.latitude,
          position.longitude,
        );
      });

      _mapController.move(_currentLocation!, 15);

      // Start listening to location updates
      _locationSubscription = MapService.getLocationStream().listen((position) {
        setState(() {
          _currentLocation = latlong.LatLng(
            position.latitude,
            position.longitude,
          );
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  void _setupSearchListeners() {
    _startController.addListener(() {
      _startDebounce?.cancel();
      _startDebounce = Timer(const Duration(milliseconds: 500), () {
        _searchLocation(_startController.text, true);
      });
    });

    _endController.addListener(() {
      _endDebounce?.cancel();
      _endDebounce = Timer(const Duration(milliseconds: 500), () {
        _searchLocation(_endController.text, false);
      });
    });
  }

  Future<void> _searchLocation(String query, bool isStart) async {
    if (query.isEmpty) {
      setState(() {
        if (isStart) {
          _startSearchResults = [];
        } else {
          _endSearchResults = [];
        }
      });
      return;
    }

    try {
      final results = await MapService.searchLocation(query);
      setState(() {
        if (isStart) {
          _startSearchResults = results;
        } else {
          _endSearchResults = results;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching location: $e')));
      }
    }
  }

  void _onStartLocationSelected(SearchResult result) {
    setState(() {
      _startLocation = result.position;
      _startController.text = result.address;
      _startSearchResults = [];
    });
    _updateMapView();
  }

  void _onEndLocationSelected(SearchResult result) {
    setState(() {
      _endLocation = result.position;
      _endController.text = result.address;
      _endSearchResults = [];
    });
    _updateMapView();
  }

  void _updateMapView() {
    if (_startLocation != null && _endLocation != null) {
      final bounds = flutter_map.LatLngBounds.fromPoints([
        _startLocation!,
        _endLocation!,
      ]);
      _mapController.fitCamera(
        flutter_map.CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } else if (_startLocation != null) {
      _mapController.move(_startLocation!, 15);
    } else if (_endLocation != null) {
      _mapController.move(_endLocation!, 15);
    }
  }

  Future<void> _findRoute() async {
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end locations'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final route = await MapService.getRoute(_startLocation!, _endLocation!);
      setState(() {
        _routeResult = route;
        _isLoading = false;
      });

      if (route.points.isNotEmpty) {
        final bounds = flutter_map.LatLngBounds.fromPoints(route.points);
        _mapController.fitCamera(
          flutter_map.CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finding route: $e')));
      }
    }
  }

  Future<void> _startNavigation() async {
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end locations'),
        ),
      );
      return;
    }

    try {
      List<routing.LngLat> waypoints = [
        routing.LngLat(
          lng: _startLocation!.longitude,
          lat: _startLocation!.latitude,
        ),
        routing.LngLat(
          lng: _endLocation!.longitude,
          lat: _endLocation!.latitude,
        ),
      ];

      // Use OSRM trip service with specific options
      final road = await manager.getRoute(
        request: routing.OSRMRequest.trip(
          waypoints: waypoints,
          destination: routing.DestinationGeoPointOption.last,
          source: routing.SourceGeoPointOption.first,
          geometries: routing.Geometries.polyline,
          steps: true, // Get turn-by-turn instructions
          languages: routing.Languages.en,
          roundTrip: false, // We want a one-way trip
          overview: routing.Overview.full, // Get full geometry
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentRoad = road;
        _instructions = road.instructions;
        _isNavigating = true;
        _currentInstructionIndex = 0;
      });

      // Start periodic location checks for navigation updates
      _navigationTimer?.cancel();
      _navigationTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _checkCurrentInstruction(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error calculating route: $e')));
      }
    }
  }

  Future<void> _checkCurrentInstruction() async {
    if (_currentRoad == null || _instructions == null || !_isNavigating) return;

    if (_currentLocation != null) {
      final currentLngLat = routing.LngLat(
        lng: _currentLocation!.longitude,
        lat: _currentLocation!.latitude,
      );

      try {
        // Calculate distance to next instruction
        final currentInstruction = _instructions![_currentInstructionIndex];

        // Simple distance-based check (can be made more sophisticated)
        final distanceToNextStep = _calculateDistance(
          currentLngLat.lat,
          currentLngLat.lng,
          currentInstruction.location.lat,
          currentInstruction.location.lng,
        );

        if (distanceToNextStep < 20 && // Within 20 meters
            _currentInstructionIndex < _instructions!.length - 1) {
          setState(() {
            _currentInstructionIndex++;
          });
        }
      } catch (e) {
        _logger.e('Error updating instruction', error: e);
      }
    }
  }

  // Helper method to calculate distance between two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _instructions = null;
      _currentInstructionIndex = 0;
      _currentRoad = null;
    });
    _navigationTimer?.cancel();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/homepage');
        break;
      case 1: // Routes
        Navigator.pushReplacementNamed(context, '/routespage');
        break;
      case 2: // Alerts
        Navigator.pushReplacementNamed(context, '/alertspage');
        break;
      case 3: // Emergency
        Navigator.pushReplacementNamed(context, '/emergencypage');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
          _isNavigating
              ? null
              : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    label: 'Routes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications),
                    label: 'Alerts',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.phone),
                    label: 'Emergency',
                  ),
                ],
              ),
      body: Stack(
        children: [
          flutter_map.FlutterMap(
            mapController: _mapController,
            options: MapService.defaultMapOptions,
            children: [
              flutter_map.TileLayer(urlTemplate: MapService.getTileLayer()),
              // Current location marker
              CurrentLocationLayer(
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(Icons.navigation, color: Colors.white),
                  ),
                  markerSize: Size(40, 40),
                  markerDirection: MarkerDirection.heading,
                  accuracyCircleColor: Colors.blue,
                ),
              ),
              // Start and end location markers
              flutter_map.MarkerLayer(
                markers: [
                  if (_startLocation != null)
                    flutter_map.Marker(
                      point: _startLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  if (_endLocation != null)
                    flutter_map.Marker(
                      point: _endLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
              // Route polyline
              if (_routeResult != null)
                flutter_map.PolylineLayer(
                  polylines: [
                    flutter_map.Polyline(
                      points: _routeResult!.points,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
          // Search panel
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Start location search
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _startController,
                      decoration: InputDecoration(
                        hintText: 'Enter start location',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_startSearchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.2,
                      ),
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _startSearchResults.length,
                        itemBuilder: (context, index) {
                          final result = _startSearchResults[index];
                          return ListTile(
                            title: Text(result.name),
                            subtitle: Text(result.address),
                            onTap: () => _onStartLocationSelected(result),
                          );
                        },
                      ),
                    ),
                  // End location search
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _endController,
                      decoration: InputDecoration(
                        hintText: 'Enter destination',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_endSearchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.2,
                      ),
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _endSearchResults.length,
                        itemBuilder: (context, index) {
                          final result = _endSearchResults[index];
                          return ListTile(
                            title: Text(result.name),
                            subtitle: Text(result.address),
                            onTap: () => _onEndLocationSelected(result),
                          );
                        },
                      ),
                    ),
                  // Find route and Start Navigation buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _findRoute,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Find Route'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _routeResult == null ? null : _startNavigation,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Start Navigation'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add navigation panel when navigating
          if (_isNavigating && _instructions != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current instruction
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _instructions![_currentInstructionIndex]
                                      .instruction,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'In ${(_instructions![_currentInstructionIndex].distance / 1000).toStringAsFixed(1)} km',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _stopNavigation,
                          ),
                        ],
                      ),
                    ),
                    // Next instruction preview
                    if (_currentInstructionIndex < _instructions!.length - 1)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _instructions![_currentInstructionIndex + 1]
                                    .instruction,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
