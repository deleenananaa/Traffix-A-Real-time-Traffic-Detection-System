// import 'package:flutter/material.dart';

// class RoutesPage extends StatelessWidget {
//   const RoutesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(appBar: AppBar(title: Text("Routes")));
//   }
// }
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  // Add this variable to track selected index
  int _selectedIndex = 1;

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

  final TextEditingController _startLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String selectedVehicleType = 'Choose Vehicle Type';

  // Sample saved routes
  final List<RouteInfo> savedRoutes = [
    RouteInfo(
      name: 'Home to Work',
      via: 'Main St.',
      duration: 20,
      congestion: 'low',
    ),
    RouteInfo(
      name: 'Gym',
      via: 'Park Ave.',
      duration: 15,
      congestion: 'medium',
    ),
  ];

  // Sample suggested routes
  List<RouteInfo> suggestedRoutes = [
    RouteInfo(
      name: 'Shortest',
      via: 'Main St.',
      duration: 18,
      congestion: 'low',
    ),
    RouteInfo(
      name: 'Fastest',
      via: 'Highway 1',
      duration: 22,
      congestion: 'medium',
    ),
    RouteInfo(
      name: 'No Tolls',
      via: 'River Rd.',
      duration: 25,
      congestion: 'high',
    ),
  ];

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Text(
                'Routes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saved Routes section
                      const Text(
                        'Saved Routes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Saved route cards
                      ...savedRoutes.map((route) => _buildRouteCard(route)),
                      const SizedBox(height: 24),

                      // Route finder form
                      TextField(
                        controller: _startLocationController,
                        decoration: InputDecoration(
                          hintText: 'Enter starting location',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Enter destination',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Vehicle type dropdown
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedVehicleType,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items:
                                [
                                  'Choose Vehicle Type',
                                  'One Wheeler',
                                  'Two Wheeler',
                                  'Emergency Vehicle',
                                ].map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedVehicleType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Find Route button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _findRoute();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Find Route',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Suggested Routes section
                      const Text(
                        'Suggested Routes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Suggested route cards
                      ...suggestedRoutes.map((route) => _buildRouteCard(route)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteInfo route) {
    Color dotColor;
    switch (route.congestion) {
      case 'low':
        dotColor = Colors.green;
        break;
      case 'medium':
        dotColor = Colors.orange;
        break;
      case 'high':
        dotColor = Colors.red;
        break;
      default:
        dotColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${route.duration} mins',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'via ${route.via}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      route.congestion,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _findRoute() {
    if (_startLocationController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        selectedVehicleType == 'Choose Vehicle Type') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Simulate finding routes with A* algorithm
    _calculateRoutes();

    setState(() {
      // Update the UI to show the new routes
    });
  }

  void _calculateRoutes() {
    // This would typically use real map data and the A* algorithm
    // For now, we'll simulate different routes based on vehicle type

    setState(() {
      suggestedRoutes = [];

      // Different route options based on vehicle type
      if (selectedVehicleType == 'One Wheeler') {
        suggestedRoutes = [
          RouteInfo(
            name: 'Shortest',
            via: 'Bike Path',
            duration: 12,
            congestion: 'low',
          ),
          RouteInfo(
            name: 'Safest',
            via: 'Park Trail',
            duration: 15,
            congestion: 'low',
          ),
        ];
      } else if (selectedVehicleType == 'Two Wheeler') {
        suggestedRoutes = [
          RouteInfo(
            name: 'Shortest',
            via: 'Main St.',
            duration: 14,
            congestion: 'medium',
          ),
          RouteInfo(
            name: 'Fastest',
            via: 'Highway 1',
            duration: 10,
            congestion: 'low',
          ),
          RouteInfo(
            name: 'Scenic',
            via: 'Coastal Rd.',
            duration: 18,
            congestion: 'low',
          ),
        ];
      } else if (selectedVehicleType == 'Emergency Vehicle') {
        suggestedRoutes = [
          RouteInfo(
            name: 'Priority',
            via: 'Main St.',
            duration: 8,
            congestion: 'low',
          ),
          RouteInfo(
            name: 'Alternate',
            via: 'Side Streets',
            duration: 10,
            congestion: 'medium',
          ),
        ];
      }
    });
  }
}

class RouteInfo {
  final String name;
  final String via;
  final int duration;
  final String congestion;

  RouteInfo({
    required this.name,
    required this.via,
    required this.duration,
    required this.congestion,
  });
}

// A* Algorithm implementation for finding shortest path
class AStarPathFinder {
  // This is a basic implementation of A* algorithm
  // In a real app, you would use more complex map data

  static List<LatLng> findPath(LatLng start, LatLng end, String vehicleType) {
    // Sample implementation of A* algorithm
    // For demonstration purposes

    // Create a grid of nodes (in a real implementation, this would be your map)
    final gridSize = 20;
    final nodes = List.generate(
      gridSize,
      (i) => List.generate(
        gridSize,
        (j) => Node(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * i / gridSize,
            start.longitude + (end.longitude - start.longitude) * j / gridSize,
          ),
          i,
          j,
        ),
      ),
    );

    // Set start and end nodes
    final startNode = nodes[0][0];
    final endNode = nodes[gridSize - 1][gridSize - 1];

    // Initialize open and closed sets
    final openSet = PriorityQueue<Node>((a, b) => a.fScore.compareTo(b.fScore));
    final openSetContents = <Node>{};
    final closedSet = <Node>{};

    // Add start node to open set
    startNode.gScore = 0;
    startNode.fScore = _heuristic(startNode, endNode);
    openSet.add(startNode);
    openSetContents.add(startNode);

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      openSetContents.remove(current);

      if (current == endNode) {
        // Path found, reconstruct and return
        return _reconstructPath(current);
      }

      closedSet.add(current);

      // Get neighbors
      final neighbors = _getNeighbors(current, nodes, gridSize);

      for (final neighbor in neighbors) {
        if (closedSet.contains(neighbor)) continue;

        // Calculate tentative gScore
        final tentativeGScore = current.gScore + _distance(current, neighbor);

        if (!openSetContents.contains(neighbor)) {
          openSet.add(neighbor);
          openSetContents.add(neighbor);
        } else if (tentativeGScore >= neighbor.gScore) {
          continue;
        }

        // This path is better, record it
        neighbor.cameFrom = current;
        neighbor.gScore = tentativeGScore;
        neighbor.fScore = neighbor.gScore + _heuristic(neighbor, endNode);
      }
    }

    // No path found
    return [];
  }

  static double _heuristic(Node a, Node b) {
    // Calculate straight-line distance (Euclidean distance)
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, a.position, b.position);
  }

  static double _distance(Node a, Node b) {
    // Calculate actual distance between adjacent nodes
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, a.position, b.position);
  }

  static List<Node> _getNeighbors(
    Node node,
    List<List<Node>> grid,
    int gridSize,
  ) {
    final neighbors = <Node>[];
    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // Cardinal directions
      [-1, -1], [-1, 1], [1, -1], [1, 1], // Diagonals
    ];

    for (final dir in directions) {
      final newI = node.i + dir[0];
      final newJ = node.j + dir[1];

      if (newI >= 0 && newI < gridSize && newJ >= 0 && newJ < gridSize) {
        neighbors.add(grid[newI][newJ]);
      }
    }

    return neighbors;
  }

  static List<LatLng> _reconstructPath(Node endNode) {
    final path = <LatLng>[];
    var current = endNode;

    while (current.cameFrom != null) {
      path.add(current.position);
      current = current.cameFrom!;
    }

    path.add(current.position); // Add start node
    return path.reversed.toList(); // Return path from start to end
  }
}

class Node {
  final LatLng position;
  final int i, j; // Grid coordinates
  Node? cameFrom;
  double gScore = double.infinity; // Cost from start to current node
  double fScore = double.infinity; // Estimated total cost (g + h)

  Node(this.position, this.i, this.j);
}
