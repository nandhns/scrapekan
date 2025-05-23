import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'week';
  String _selectedMetric = 'waste';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilters(),
            SizedBox(height: 24),
            _buildChart(),
            SizedBox(height: 24),
            _buildMetricsGrid(),
            SizedBox(height: 24),
            _buildTopPerformers(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'week', child: Text('Week')),
                      DropdownMenuItem(value: 'month', child: Text('Month')),
                      DropdownMenuItem(value: 'year', child: Text('Year')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMetric,
                    decoration: InputDecoration(
                      labelText: 'Metric',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'waste', child: Text('Waste')),
                      DropdownMenuItem(value: 'co2', child: Text('CO₂ Saved')),
                      DropdownMenuItem(value: 'users', child: Text('Users')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMetric = value!);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: _getDataStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final data = _processChartData(snapshot.data?.docs ?? []);

                  return data.spots.isEmpty
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
                                    if (value.toInt() >= 0 && value.toInt() < data.labels.length) {
                                      return Text(
                                        data.labels[value.toInt()],
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
                                spots: data.spots,
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
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getDataStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final metrics = _calculateMetrics(snapshot.data?.docs ?? []);

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildMetricCard(
              'Total',
              metrics['total']?.toStringAsFixed(1) ?? '0.0',
              Icons.assessment,
              Colors.blue,
            ),
            _buildMetricCard(
              'Average',
              metrics['average']?.toStringAsFixed(1) ?? '0.0',
              Icons.trending_up,
              Colors.green,
            ),
            _buildMetricCard(
              'Peak',
              metrics['peak']?.toStringAsFixed(1) ?? '0.0',
              Icons.arrow_upward,
              Colors.orange,
            ),
            _buildMetricCard(
              'Growth',
              '${metrics['growth']?.toStringAsFixed(1) ?? '0.0'}%',
              Icons.show_chart,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopPerformers() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('points', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];

                return Column(
                  children: users.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          data['name'][0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      title: Text(data['name']),
                      subtitle: Text('Points: ${data['points']}'),
                      trailing: Icon(Icons.star, color: Colors.amber),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getDataStream() {
    var query = FirebaseFirestore.instance.collection('waste_collections');
    
    DateTime startDate;
    switch (_selectedPeriod) {
      case 'week':
        startDate = DateTime.now().subtract(Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime.now().subtract(Duration(days: 30));
        break;
      case 'year':
        startDate = DateTime.now().subtract(Duration(days: 365));
        break;
      default:
        startDate = DateTime.now().subtract(Duration(days: 7));
    }

    return query
        .where('timestamp', isGreaterThan: startDate)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  ChartData _processChartData(List<QueryDocumentSnapshot> docs) {
    Map<String, double> dailyData = {};

    for (var doc in docs.reversed) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateStr = '${date.day}/${date.month}';
      final value = _getMetricValue(data);

      dailyData[dateStr] = (dailyData[dateStr] ?? 0) + value;
    }

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ChartData(
      spots: List.generate(
        sortedEntries.length,
        (index) => FlSpot(index.toDouble(), sortedEntries[index].value),
      ),
      labels: sortedEntries.map((e) => e.key).toList(),
    );
  }

  Map<String, double> _calculateMetrics(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return {
        'total': 0,
        'average': 0,
        'peak': 0,
        'growth': 0,
      };
    }

    double total = 0;
    double peak = 0;
    Map<String, double> dailyTotals = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateStr = '${date.day}/${date.month}';
      final value = _getMetricValue(data);

      total += value;
      peak = value > peak ? value : peak;
      dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0) + value;
    }

    final average = total / docs.length;
    
    // Calculate growth
    final values = dailyTotals.values.toList();
    if (values.length >= 2) {
      final oldValue = values.first;
      final newValue = values.last;
      final growth = oldValue > 0 ? ((newValue - oldValue) / oldValue) * 100 : 0;
      
      return {
        'total': total,
        'average': average,
        'peak': peak,
        'growth': growth.toDouble(),
      };
    }

    return {
      'total': total,
      'average': average,
      'peak': peak,
      'growth': 0,
    };
  }

  double _getMetricValue(Map<String, dynamic> data) {
    switch (_selectedMetric) {
      case 'waste':
        return (data['weight'] as num).toDouble();
      case 'co2':
        return (data['weight'] as num).toDouble() * 2.5; // Example conversion
      case 'users':
        return 1; // Count each entry as one user interaction
      default:
        return 0;
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final List<FlSpot> spots;
  final List<String> labels;

  ChartData({required this.spots, required this.labels});
} 