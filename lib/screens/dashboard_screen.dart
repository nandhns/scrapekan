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
  String _selectedPeriod = 'This Month';

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
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Waste Dropped',
                  '24',
                  'kg',
                  Icons.delete_outline,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Compost Created',
                  '8',
                  'kg',
                  Icons.eco,
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'CO2 Saved',
                  '12',
                  'kg',
                  Icons.cloud_done,
                  Colors.blue,
                ),
              ),
            ],
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
                  _buildActivityItem(
                    'Dropped off organic waste',
                    'Pasar Tani Kekal Pekan',
                    '3.5 kg',
                    DateTime.now().subtract(Duration(hours: 2)),
                  ),
                  Divider(),
                  _buildActivityItem(
                    'Collected compost',
                    'Taman Tas Collection Center',
                    '2 kg',
                    DateTime.now().subtract(Duration(days: 1)),
                  ),
                  Divider(),
                  _buildActivityItem(
                    'Dropped off organic waste',
                    'Pasar Tani Kekal Gambang',
                    '4 kg',
                    DateTime.now().subtract(Duration(days: 3)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildActivityItem(
    String title,
    String location,
    String amount,
    DateTime time,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco,
              color: Colors.green,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _getTimeAgo(time),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
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