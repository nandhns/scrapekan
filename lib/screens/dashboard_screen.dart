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
  double _totalWaste = 0;
  double _co2Saved = 0;
  List<FlSpot> _monthlyData = [];
  List<String> _monthLabels = [];

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
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) return;

      final wasteLogs = await FirebaseFirestore.instance
          .collection('waste_logs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      double totalWaste = 0;
      Map<String, double> monthlyWaste = {};

      for (var doc in wasteLogs.docs) {
        final data = doc.data();
        final weight = data['weight'] as double;
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
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Dashboard')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
                  SizedBox(height: 24),
                  Text(
                    'Monthly Waste Contribution',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  _buildWasteChart(),
                  SizedBox(height: 24),
                  _buildAchievements(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Waste',
            '${_totalWaste.toStringAsFixed(1)} kg',
            Icons.delete_outline,
            Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'CO₂ Saved',
            '${_co2Saved.toStringAsFixed(1)} kg',
            Icons.eco_outlined,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteChart() {
    return Container(
      height: 300,
      child: _monthlyData.isEmpty
          ? Center(child: Text('No data available'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _monthLabels.length) {
                          return Text(
                            _monthLabels[value.toInt()],
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _monthlyData,
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAchievements() {
    final nextTier = _getNextClimateTier();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        _buildAchievementCard(
          'Eco Warrior',
          'Contributed more than 10kg of waste',
          _totalWaste >= 10,
        ),
        SizedBox(height: 8),
        ..._climateTiers.map((tier) => Column(
          children: [
            _buildAchievementCard(
              tier['name'],
              'Saved more than ${tier['threshold']}kg of CO₂',
              _co2Saved >= tier['threshold'],
            ),
            SizedBox(height: 8),
          ],
        )).toList(),
        if (_co2Saved >= _climateTiers.last['threshold']) ...[
          _buildAchievementCard(
            nextTier['name'],
            'Next milestone: Save ${nextTier['threshold']}kg of CO₂',
            false,
          ),
          SizedBox(height: 8),
        ],
        _buildAchievementCard(
          'Consistent Contributor',
          'Logged waste for 3 consecutive months',
          _monthlyData.length >= 3,
        ),
        // Add progress indicator for next tier
        if (_co2Saved < nextTier['threshold']) ...[
          SizedBox(height: 16),
          Text(
            'Progress to ${nextTier['name']}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: _co2Saved / nextTier['threshold'],
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 4),
          Text(
            '${_co2Saved.toStringAsFixed(1)}/${nextTier['threshold']}kg CO₂ saved',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementCard(String title, String description, bool isUnlocked) {
    return Card(
      child: ListTile(
        leading: Icon(
          isUnlocked ? Icons.stars : Icons.star_border,
          color: isUnlocked ? Colors.amber : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: isUnlocked
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
} 