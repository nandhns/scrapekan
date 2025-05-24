import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _totalWaste = 0;
  double _co2Saved = 0;
  List<FlSpot> _monthlyData = [];
  List<String> _monthLabels = [];
  Stream<QuerySnapshot>? _wasteLogsStream;

  // Map of location IDs to readable names
  final Map<String, String> _dropOffLocations = {
    'loc1': 'Pasar Tani Kekal Pekan',
    'loc2': 'Pasar Tani Kekal Gambang',
    'loc3': 'Taman Tas Collection Center',
    'loc4': 'Bandar Putra Collection Point',
  };

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

  // Add tier thresholds
  final List<Map<String, dynamic>> _climateTiers = [
    {'name': 'Bronze Climate Champion', 'threshold': 25},
    {'name': 'Silver Climate Champion', 'threshold': 50},
    {'name': 'Gold Climate Champion', 'threshold': 100},
    {'name': 'Platinum Climate Champion', 'threshold': 250},
    {'name': 'Diamond Climate Champion', 'threshold': 500},
    {'name': 'Master Climate Champion', 'threshold': 1000},
    {'name': 'Legendary Climate Champion', 'threshold': 2500},
    {'name': 'Supreme Climate Champion', 'threshold': 5000},
  ];

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'User not logged in';
      });
      return;
    }

    setState(() {
      _wasteLogsStream = FirebaseFirestore.instance
          .collection('waste_logs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    });
  }

  void _updateStreamForPeriod(String period) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) return;

    DateTime startDate;
    final now = DateTime.now();

    switch (period) {
      case 'week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(Duration(days: 30));
    }

    setState(() {
      _wasteLogsStream = FirebaseFirestore.instance
          .collection('waste_logs')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: true)
          .snapshots();
    });
  }

  // Add method to get next tier
  Map<String, dynamic> _getNextClimateTier() {
    for (var tier in _climateTiers) {
      if (_co2Saved < tier['threshold']) {
        return tier;
      }
    }
    // If beyond all tiers, create a dynamic next milestone
    final lastTier = _climateTiers.last;
    final multiplier = (_co2Saved / lastTier['threshold']).ceil();
    return {
      'name': 'Elite Climate Champion Tier $multiplier',
      'threshold': lastTier['threshold'] * multiplier
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Impact',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatCard(
                        icon: Icons.eco,
                        value: '${_totalWaste.toStringAsFixed(1)} kg',
                        label: 'Total Waste',
                      ),
                      _StatCard(
                        icon: Icons.co2,
                        value: '${_co2Saved.toStringAsFixed(1)} kg',
                        label: 'CO₂ Saved',
                      ),
                      _StatCard(
                        icon: Icons.star,
                        value: '150',
                        label: 'Points',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Card(
            child: StreamBuilder<QuerySnapshot>(
              stream: _wasteLogsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error loading activities: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final activities = snapshot.data?.docs ?? [];

                if (activities.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No waste logs yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: activities.length.clamp(0, 5),
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    Map<String, dynamic>? activityData;
                    try {
                      activityData = activities[index].data() as Map<String, dynamic>;
                    } catch (e) {
                      print('Error casting activity data: $e');
                      return SizedBox.shrink();
                    }

                    String timeAgo = '';
                    String locationName = 'Unknown Location';
                    double weight = 0;
                    
                    try {
                      if (activityData.containsKey('timestamp')) {
                        final timestamp = activityData['timestamp'] as Timestamp;
                        final date = timestamp.toDate();
                        timeAgo = _getTimeAgo(date);
                      }
                      
                      if (activityData.containsKey('location')) {
                        final location = activityData['location'] as String?;
                        locationName = _dropOffLocations[location] ?? 'Unknown Location';
                      }
                      
                      if (activityData.containsKey('weight')) {
                        weight = (activityData['weight'] as num).toDouble();
                      }
                    } catch (e) {
                      print('Error processing activity fields: $e');
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.recycling, color: Colors.green),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${weight.toStringAsFixed(1)}kg waste dropped off',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '$locationName • $timeAgo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _AchievementTile(
                  icon: Icons.eco,
                  title: 'Green Warrior',
                  progress: 0.7,
                  level: 'Level 3',
                ),
                Divider(),
                _AchievementTile(
                  icon: Icons.recycling,
                  title: 'Recycling Master',
                  progress: 0.4,
                  level: 'Level 2',
                ),
                Divider(),
                _AchievementTile(
                  icon: Icons.nature_people,
                  title: 'Community Hero',
                  progress: 0.2,
                  level: 'Level 1',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processWasteLogs(List<QueryDocumentSnapshot> wasteLogs) {
    double totalWaste = 0;
    Map<String, double> monthlyWaste = {};

    for (var doc in wasteLogs) {
      final data = doc.data() as Map<String, dynamic>;
      final weight = (data['weight'] as num).toDouble();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final monthKey = DateFormat('MMM yyyy').format(timestamp);

      totalWaste += weight;
      monthlyWaste[monthKey] = (monthlyWaste[monthKey] ?? 0) + weight;
    }

    final sortedEntries = monthlyWaste.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    setState(() {
      _totalWaste = totalWaste;
      _co2Saved = totalWaste * 2.5;
      _monthlyData = List.generate(
        sortedEntries.length,
        (index) => FlSpot(index.toDouble(), sortedEntries[index].value),
      );
      _monthLabels = sortedEntries.map((e) => e.key).toList();
      _isLoading = false;
    });
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