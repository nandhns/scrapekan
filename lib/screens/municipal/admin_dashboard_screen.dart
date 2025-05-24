import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Overview of compost production and distribution',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              
              // Summary Cards
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('statistics')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final stats = snapshot.data?.docs.first.data() as Map<String, dynamic>? ?? {};
                  final totalProduced = (stats['totalProduced'] as num?)?.toDouble() ?? 0;
                  final activeContributors = (stats['activeContributors'] as num?)?.toInt() ?? 0;
                  final scheduledDeliveries = (stats['scheduledDeliveries'] as num?)?.toInt() ?? 0;
                  final co2Saved = (stats['co2Saved'] as num?)?.toDouble() ?? 0;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: isWide ? (constraints.maxWidth - 48) / 2 : constraints.maxWidth,
                            child: _buildStatCard(
                              'Compost',
                              '${totalProduced.toStringAsFixed(0)}kg',
                              'Total produced',
                              Icons.compost,
                              Colors.green,
                            ),
                          ),
                          SizedBox(
                            width: isWide ? (constraints.maxWidth - 48) / 2 : constraints.maxWidth,
                            child: _buildStatCard(
                              'Contributors',
                              activeContributors.toString(),
                              'Active this month',
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(
                            width: isWide ? (constraints.maxWidth - 48) / 2 : constraints.maxWidth,
                            child: _buildStatCard(
                              'Deliveries',
                              scheduledDeliveries.toString(),
                              'Scheduled this week',
                              Icons.local_shipping,
                              Colors.orange,
                            ),
                          ),
                          SizedBox(
                            width: isWide ? (constraints.maxWidth - 48) / 2 : constraints.maxWidth,
                            child: _buildStatCard(
                              'CO₂ Saved',
                              '${co2Saved.toStringAsFixed(0)}kg',
                              'Environmental impact',
                              Icons.eco,
                              Colors.teal,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 24),
              
              // Inventory Status
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 24),
                      Container(
                        height: 300,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('inventory')
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

                            final data = snapshot.data?.docs ?? [];
                            if (data.isEmpty) {
                              return Center(child: Text('No inventory data available'));
                            }

                            return LineChart(
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
                                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                                          final doc = data[value.toInt()];
                                          final timestamp = (doc['timestamp'] as Timestamp).toDate();
                                          return Text(
                                            DateFormat('MM/dd').format(timestamp),
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
                                    spots: List.generate(data.length, (index) {
                                      final doc = data[index];
                                      return FlSpot(
                                        index.toDouble(),
                                        (doc['quantity'] as num).toDouble(),
                                      );
                                    }),
                                    isCurved: true,
                                    color: Theme.of(context).primaryColor,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
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
} 