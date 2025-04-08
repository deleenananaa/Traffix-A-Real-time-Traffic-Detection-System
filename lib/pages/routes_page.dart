import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  // Add this variable to track selected index
  int _selectedIndex = 1;
  final MapController _mapController = MapController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  LatLng? _currentLocation;
  LatLng? _startLocation;
  LatLng? _endLocation;
  List<SearchResult> _startSearchResults = [];
  List<SearchResult> _endSearchResults = [];
  RouteResult? _routeResult;
  bool _isLoading = false;
  Timer? _startDebounce;
  Timer? _endDebounce;
  StreamSubscription<Position>? _locationSubscription;

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
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await MapService.getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_currentLocation!, 15);

      // Start listening to location updates
      _locationSubscription = MapService.getLocationStream().listen((position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
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
      final bounds = LatLngBounds.fromPoints([_startLocation!, _endLocation!]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
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
        final bounds = LatLngBounds.fromPoints(route.points);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Routes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Emergency'),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapService.defaultMapOptions,
            children: [
              TileLayer(urlTemplate: MapService.getTileLayer()),
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
              MarkerLayer(
                markers: [
                  if (_startLocation != null)
                    Marker(
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
                    Marker(
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
                PolylineLayer(
                  polylines: [
                    Polyline(
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
                  // Find route button
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
