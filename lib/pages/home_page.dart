import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'dart:async';
import '../services/map_service.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_overlay.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _debounce;
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TrafficService _trafficService;
  List<TrafficData> _trafficData = [];
  List<TrafficIncident> _incidents = [];
  StreamSubscription? _trafficSubscription;
  StreamSubscription? _incidentsSubscription;

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5, // Update every 5 meters
    timeLimit: Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _trafficService = TrafficService();
    _initializeLocation();
    _initializeTrafficData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _positionStreamSubscription?.cancel();
    _trafficSubscription?.cancel();
    _incidentsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // First get the current position with high accuracy
      Position position = await _determinePosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Move map to current position
      _mapController.move(
        _currentPosition!,
        18,
      ); // Increased zoom for better detail

      // Then start listening to position updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('Location Services Disabled'),
                content: const Text(
                  'Please enable location services to use this app.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Open Settings'),
                    onPressed: () {
                      Navigator.pop(context);
                      Geolocator.openLocationSettings();
                    },
                  ),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('Location Permission Required'),
                content: const Text(
                  'Location permissions are permanently denied. Please enable them in your device settings.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Open Settings'),
                    onPressed: () {
                      Navigator.pop(context);
                      Geolocator.openAppSettings();
                    },
                  ),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      ),
    );
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

  void signUserOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        try {
          final results = await MapService.searchLocation(query);
          if (mounted) {
            setState(() {
              _searchResults = results;
              _isSearching = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error searching location: $e')),
            );
          }
        }
      }
    });
  }

  void _onSearchResultTapped(SearchResult result) {
    _mapController.move(result.position, 16);
    setState(() {
      _searchResults = [];
      _searchController.text = result.address;
      _isSearching = false;
    });
  }

  void _initializeTrafficData() {
    _trafficSubscription = _trafficService.trafficDataStream.listen((data) {
      setState(() {
        _trafficData = data;
      });
    });

    _incidentsSubscription = _trafficService.incidentsStream.listen((
      incidents,
    ) {
      setState(() {
        _incidents = incidents;
      });
    });
  }

  void _showIncidentDialog(BuildContext context) {
    String selectedType = 'accident';
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report Traffic Incident'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  items:
                      ['accident', 'construction', 'roadblock', 'other']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase()),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    selectedType = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter incident details...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_currentPosition != null) {
                    _trafficService.reportIncident(
                      TrafficIncident(
                        id: const Uuid().v4(),
                        location: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        type: selectedType,
                        description: descriptionController.text,
                        reportTime: DateTime.now(),
                        status: 'active',
                        reportedBy:
                            user?.uid ?? '', // Replace with actual user ID
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Report'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 70,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    'Traffix',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).dividerColor),
            //profile page list tile
            ListTile(
              leading: Icon(
                Icons.person,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .6),
              ),
              title: Text(
                "Profile",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profilepage');
              },
            ),
            //settings page list tile
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .6),
              ),
              title: Text(
                "Settings",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settingspage');
              },
            ),
            Divider(color: Theme.of(context).dividerColor),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                "Sign Out",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                signUserOut();
              },
            ),
          ],
        ),
      ),
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
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition ?? const LatLng(0, 0),
                initialZoom: 18, // Increased initial zoom
                minZoom: 3,
                maxZoom: 19, // Increased max zoom
                keepAlive: true,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapService.getTileLayer(),
                  userAgentPackageName: 'com.traffix.app',
                ),
                if (_trafficData.isNotEmpty || _incidents.isNotEmpty)
                  TrafficOverlay(
                    trafficData: _trafficData,
                    incidents: _incidents,
                    onIncidentTap: (incident) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${incident.type}: ${incident.description}',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                CurrentLocationLayer(
                  positionStream: _createPositionStream(),
                  style: const LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: Icon(Icons.navigation, color: Colors.white),
                    ),
                    markerSize: Size(40, 40),
                    accuracyCircleColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).shadowColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                              child: Icon(
                                Icons.menu,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Traffix',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: .6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search for a destination.....',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: .4),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  suffixIcon: _buildSuffixIcon(),
                                  fillColor:
                                      Theme.of(context).colorScheme.surface,
                                  filled: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  _searchResults.map((result) {
                                    return InkWell(
                                      onTap:
                                          () => _onSearchResultTapped(result),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: .6),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    result.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    result.address,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: .6,
                                                          ),
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 100,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.my_location,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      if (_currentPosition != null) {
                        _mapController.move(_currentPosition!, 18);
                      }
                    },
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        currentZoom + 1,
                      );
                    },
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  IconButton(
                    icon: Icon(
                      Icons.remove,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(
                        _mapController.camera.center,
                        currentZoom - 1,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showIncidentDialog(context),
            backgroundColor: Theme.of(context).colorScheme.error,
            child: Icon(
              Icons.report_problem,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (_isSearching) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
          ),
        ),
      );
    }
    if (_searchController.text.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.clear, color: Colors.grey.shade600),
        onPressed: () {
          _searchController.clear();
          setState(() {
            _searchResults = [];
          });
        },
      );
    }
    return const SizedBox.shrink();
  }

  Stream<LocationMarkerPosition> _createPositionStream() {
    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (Position position) => LocationMarkerPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      ),
    );
  }
}
