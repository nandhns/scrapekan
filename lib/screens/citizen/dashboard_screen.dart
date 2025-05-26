import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import '../../services/auth_service.dart';
import '../../services/waste_service.dart';
import '../../models/firestore_schema.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String _selectedPeriod = 'This Month';
  late final WasteService _wasteService;
  late final AuthService _authService;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeServices();
      _isInitialized = true;
    }
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Ensure Firebase is initialized
      try {
        await Firebase.initializeApp();
        print('Firebase core initialized');
      } catch (e) {
        print('Firebase initialization error: $e');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize Firebase: ${e.toString()}';
        });
        return;
      }

      _wasteService = WasteService();
      _authService = Provider.of<AuthService>(context, listen: false);

      final user = _authService.currentUser;
      if (user == null || !mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Please log in to view your dashboard';
        });
        return;
      }

      // Verify Firebase connection with proper error handling
      try {
        // First check if Firebase is initialized
        if (!FirebaseFirestore.instance.app.isAutomaticDataCollectionEnabled) {
          FirebaseFirestore.instance.app.setAutomaticDataCollectionEnabled(true);
        }
        
        // Do a simple existence check first
        if (FirebaseFirestore.instance == null) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Firebase instance is null',
          );
        }

        // Then try a simple query
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('waste_logs')
            .limit(1)
            .get()
            .timeout(
              Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Firebase connection timed out'),
            );
            
        print('Firebase connection verified successfully. Got ${snapshot.size} documents');
      } catch (e) {
        print('Firebase connection error: $e');
        if (e is FirebaseException) {
          print('Firebase error code: ${e.code}');
          print('Firebase error message: ${e.message}');
        }
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to connect to database: ${e.toString()}';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Service initialization error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to initialize services: $e';
      });
    }
  }

  @override
  void dispose() {
    _wasteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage ?? 'An error occurred'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('Retrying initialization...');
                _initializeServices();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    final user = _authService.currentUser;
    if (user == null) {
      return Center(
        child: Text('Please log in to view your dashboard'),
      );
    }

    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My Impact Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your contribution to sustainability',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          // Period Selector
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Contributions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    items: ['This Month', 'Last Month', 'This Year']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                        });
                      }
                    },
                    underline: Container(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Impact Metrics
          StreamBuilder<List<WasteLog>>(
            stream: _wasteService.userWasteLogs,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();
              final startDate = _getStartDate(_selectedPeriod, now);
              
              final filteredLogs = snapshot.data!.where((log) {
                return log.timestamp.isAfter(startDate);
              }).toList();

              double totalWaste = 0;
              double totalCompost = 0;
              double co2Saved = 0;

              for (var log in filteredLogs) {
                totalWaste += log.weight;
                // Assume all waste will eventually be composted
                totalCompost += log.weight * 0.3; // 30% compost yield
                co2Saved += log.weight * 0.5; // 0.5kg CO2 per kg waste
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Waste Dropped',
                      totalWaste.toStringAsFixed(1),
                      'kg',
                      Icons.delete_outline,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Compost Created',
                      totalCompost.toStringAsFixed(1),
                      'kg',
                      Icons.eco,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'CO2 Saved',
                      co2Saved.toStringAsFixed(1),
                      'kg',
                      Icons.cloud_done,
                      Colors.blue,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24),

          // Recent Activity
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<List<WasteLog>>(
                    stream: _wasteService.userWasteLogs,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final logs = snapshot.data!;

                      if (logs.isEmpty) {
                        return Center(
                          child: Text(
                            'No activity yet. Start by logging your waste!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: logs.length > 5 ? 5 : logs.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return FutureBuilder<String>(
                            future: _getLocationName(log),
                            builder: (context, locationSnapshot) {
                              String locationName = 'Loading...';
                              if (locationSnapshot.hasData) {
                                locationName = locationSnapshot.data!;
                              } else if (locationSnapshot.hasError) {
                                locationName = 'Error loading location';
                                print('Error loading location: ${locationSnapshot.error}');
                              }
                              
                              return ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.eco,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Dropped off organic waste',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(locationName),
                                    Text(
                                      '${log.weight} kg • ${_getTimeAgo(log.timestamp)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getStartDate(String period, DateTime now) {
    switch (period) {
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last Month':
        return DateTime(now.year, now.month - 1, 1);
      case 'This Year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }



  Future<String> _getLocationName(WasteLog log) async {
    try {
      // Handle old format (location field)
      if (log.dropOffPointId.isEmpty && (log.data?['location'] as String?)?.isNotEmpty == true) {
        return log.data?['location'] as String? ?? 'Unknown Location';
      }
      
      // Handle new format (dropOffPointId field)
      if (log.dropOffPointId.isNotEmpty) {
        final snapshot = await _wasteService.dropoffPointsRef.doc(log.dropOffPointId).get();
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>?;
          return data?['name'] as String? ?? 'Unknown Location';
        }
      }
      
      return 'Unknown Location';
    } catch (e) {
      print('Error getting location name: $e');
      return 'Error loading location';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double progress;
  final String level;

  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.progress,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
          ),
          SizedBox(height: 4),
          Text(level),
        ],
      ),
    );
  }
} 