import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong;
import '../services/map_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:graphhooper_route_navigation/graphhooper_route_navigation.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
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
  final ApiRequest _apiRequest = ApiRequest();

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
      final directionRouteResponse = await _apiRequest
          .getDrivingRouteUsingGraphHooper(
            source: LatLng(_startLocation!.latitude, _startLocation!.longitude),
            destination: LatLng(
              _endLocation!.latitude,
              _endLocation!.longitude,
            ),
            graphHooperApiKey: "4428d23a-1fa5-4d94-9409-7d87dd50c132",
            navigationType: NavigationProfile.car,
          );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => NavigationWrapperScreen(
                directionRouteResponse: directionRouteResponse,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting navigation: $e')),
        );
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
        ],
      ),
    );
  }
}
