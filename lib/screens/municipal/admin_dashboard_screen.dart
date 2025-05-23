import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCards(),
            SizedBox(height: 24),
            _WasteCollectionChart(),
            SizedBox(height: 24),
            _RecentActivities(),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('waste_collections')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final collections = snapshot.data?.docs ?? [];
        final stats = _calculateStats(collections);

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Total Waste',
              '${stats['totalWaste']?.toStringAsFixed(1) ?? '0.0'} kg',
              Icons.delete,
              Colors.red,
            ),
            _buildStatCard(
              'Active Users',
              stats['activeUsers']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'CO₂ Saved',
              '${stats['co2Saved']?.toStringAsFixed(1) ?? '0.0'} kg',
              Icons.eco,
              Colors.green,
            ),
            _buildStatCard(
              'Efficiency',
              '${stats['efficiency']?.toStringAsFixed(1) ?? '0.0'}%',
              Icons.speed,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Map<String, double> _calculateStats(List<QueryDocumentSnapshot> collections) {
    double totalWaste = 0;
    Set<String> activeUsers = {};

    for (var doc in collections) {
      final data = doc.data() as Map<String, dynamic>;
      totalWaste += (data['weight'] as num).toDouble();
      activeUsers.add(data['userId'] as String);
    }

    return {
      'totalWaste': totalWaste,
      'activeUsers': activeUsers.length.toDouble(),
      'co2Saved': totalWaste * 2.5,
      'efficiency': (activeUsers.length / 100) * 100,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
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
                fontSize: 20,
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

class _WasteCollectionChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waste Collection Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('waste_collections')
                    .orderBy('timestamp', descending: true)
                    .limit(30)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final collections = snapshot.data?.docs ?? [];
                  final data = _processChartData(collections);

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

  ChartData _processChartData(List<QueryDocumentSnapshot> collections) {
    Map<String, double> dailyData = {};

    for (var doc in collections.reversed) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateStr = '${date.day}/${date.month}';
      final weight = (data['weight'] as num).toDouble();

      dailyData[dateStr] = (dailyData[dateStr] ?? 0) + weight;
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
}

class ChartData {
  final List<FlSpot> spots;
  final List<String> labels;

  ChartData({required this.spots, required this.labels});
}

class _RecentActivities extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('waste_collections')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final activities = snapshot.data?.docs ?? [];

                return Column(
                  children: activities.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp;
                    final date = timestamp.toDate();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Icon(Icons.recycling, color: Colors.white),
                      ),
                      title: Text(
                        'Waste Collection: ${data['weight']} kg',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Location: ${data['location'] ?? 'Unknown'}\n'
                        'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                      ),
                      isThreeLine: true,
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
} 