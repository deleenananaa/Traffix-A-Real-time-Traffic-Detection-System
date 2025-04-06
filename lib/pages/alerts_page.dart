import 'package:flutter/material.dart';
import 'dart:async';
import '../services/tomtom_service.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  int _selectedIndex = 2; // Set to 3 for alerts tab

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

  final TomTomService _tomtomService = TomTomService();
  List<TrafficIncident> _incidents = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    // Refresh incidents every 5 minutes
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadIncidents(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final incidents = await _tomtomService.getTrafficIncidents();

      if (mounted) {
        setState(() {
          _incidents = incidents;
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading traffic incidents: $e')),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Traffic Alerts',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadIncidents,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Status bar
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live traffic updates for Kathmandu Valley${_lastUpdated != null ? ' • Updated ${_getTimeAgo(_lastUpdated!)}' : ''}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            // Incidents list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _incidents.isEmpty
                      ? const Center(
                        child: Text('No active incidents in Kathmandu Valley'),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadIncidents,
                        child: ListView.builder(
                          itemCount: _incidents.length,
                          itemBuilder: (context, index) {
                            final incident = _incidents[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: incident.severityColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    incident.typeIcon,
                                    color: incident.severityColor,
                                  ),
                                ),
                                title: Text(
                                  incident.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Location: ${incident.roadName}'),
                                    Text(
                                      'Status: ${incident.severityLevel}',
                                      style: TextStyle(
                                        color: incident.severityColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (incident.delay > 0)
                                      Text(
                                        'Delay: ${(incident.delay / 60).round()} minutes',
                                      ),
                                    Text(
                                      'Started: ${_getTimeAgo(incident.startTime)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () => _showIncidentDetails(incident),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIncidentDetails(TrafficIncident incident) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: incident.severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        incident.typeIcon,
                        color: incident.severityColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.type.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            incident.severityLevel,
                            style: TextStyle(
                              color: incident.severityColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(incident.roadName),
                const SizedBox(height: 12),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(incident.description),
                if (incident.delay > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Expected Delay',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${(incident.delay / 60).round()} minutes'),
                ],
                const SizedBox(height: 12),
                Text(
                  'Time Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Started: ${incident.startTime.toString()}\n${incident.endTime != null ? 'Expected end: ${incident.endTime.toString()}' : 'End time: Not available'}',
                ),
                if (incident.length > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Affected Area',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${(incident.length / 1000).toStringAsFixed(1)} km'),
                ],
              ],
            ),
          ),
    );
  }
}
