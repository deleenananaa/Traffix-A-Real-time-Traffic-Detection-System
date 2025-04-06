import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  // Add this variable to track selected index
  int _selectedIndex = 0;

  // Add this method to handle navigation
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

  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      //return Future.error('Location services are disabled.');

      // Show dialog when location is disabled
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
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        //return Future.error('Location permissions are denied');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      // return Future.error(
      //  'Location permissions are permanently denied, we cannot request permissions.',
      // );

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
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  // signout function
  void signUserOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Traffix',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for a destination',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            //profile page list tile
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () {
                //pop drawer first
                Navigator.pop(context);

                //go to home page
                Navigator.pushNamed(context, '/profilepage');
              },
            ),

            //settings page list tile
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                //pop drawer first
                Navigator.pop(context);

                //go to settings page
                Navigator.pushNamed(context, '/settingspage');
              },
            ),
          ],
        ),
      ),

      // BottomNavigationBar in the build method
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
          // Map layer
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(0, 0),
                initialZoom: 10,
                minZoom: 0,
                maxZoom: 100,
              ),
              children: [
                //display osm tiles
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                //display location marker
                CurrentLocationLayer(
                  style: LocationMarkerStyle(
                    marker: DefaultLocationMarker(
                      child: Icon(Icons.location_pin, color: Colors.blue),
                    ),
                    markerSize: const Size(30, 30),
                    markerDirection: MarkerDirection.heading,
                  ),
                ),
              ],
            ),
          ),
          // Zoom controls - moved outside FlutterMap children
          Positioned(
            left: 16,
            top: 100,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 10.0),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        },
                      ),
                      const Divider(height: 1, thickness: 1),
                      IconButton(
                        icon: const Icon(Icons.remove),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
