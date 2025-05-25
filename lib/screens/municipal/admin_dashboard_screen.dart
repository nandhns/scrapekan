import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Stream<Map<String, dynamic>> _getDashboardData() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Get processed waste for compost production
    final wasteStream = FirebaseFirestore.instance
        .collection('waste_logs')
        .where('status', isEqualTo: 'processed')
        .snapshots();

    // Get active contributors this month
    final contributorsStream = FirebaseFirestore.instance
        .collection('waste_logs')
        .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
        .snapshots();

    // Get scheduled deliveries this week
    final deliveriesStream = FirebaseFirestore.instance
        .collection('fertilizer_requests')
        .where('status', whereIn: ['pending', 'scheduled'])
        .where('deliveryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('deliveryDate', isLessThanOrEqualTo: Timestamp.fromDate(startOfWeek.add(Duration(days: 7))))
        .snapshots();

    // Combine all streams
    return Rx.combineLatest3(
      wasteStream,
      contributorsStream,
      deliveriesStream,
      (
        QuerySnapshot wasteLogs,
        QuerySnapshot contributors,
        QuerySnapshot deliveries,
      ) {
        // Calculate total compost produced
        num totalCompost = 0;
        for (var doc in wasteLogs.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalCompost += data['weight'] as num? ?? 0;
        }

        // Calculate CO2 saved (0.5kg CO2 per kg waste)
        final co2Saved = totalCompost * 0.5;

        // Get unique contributors this month
        final uniqueContributors = contributors.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String?)
            .where((id) => id != null)
            .toSet()
            .length;

        // Count scheduled deliveries
        final scheduledDeliveries = deliveries.docs.length;

        print('Found ${deliveries.docs.length} scheduled deliveries'); // Debug print
        deliveries.docs.forEach((doc) {  // Debug print
          final data = doc.data() as Map<String, dynamic>;
          print('Delivery: ${data['status']} - Date: ${(data['deliveryDate'] as Timestamp).toDate()}');
        });

        return {
          'totalCompost': totalCompost,
          'activeContributors': uniqueContributors,
          'scheduledDeliveries': scheduledDeliveries,
          'co2Saved': co2Saved,
        };
      },
    );
  }

  Stream<Map<String, dynamic>> _getInventoryData() {
    return FirebaseFirestore.instance
        .collection('inventory')
        .doc('compost')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'current': 0,
          'total': 500, // Default capacity
        };
      }
      final data = doc.data() as Map<String, dynamic>;
      return {
        'current': data['current'] ?? 0,
        'total': data['capacity'] ?? 500,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              
              StreamBuilder<Map<String, dynamic>>(
                stream: _getDashboardData(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data ?? {
                    'totalCompost': 0,
                    'activeContributors': 0,
                    'scheduledDeliveries': 0,
                    'co2Saved': 0,
                  };

                  return Column(
                    children: [
                      // First Row - Two Boxes
                      Row(
                        children: [
                          // Left Box - Compost Production
                          Expanded(
                            child: _buildStatBox(
                              title: 'Compost',
                              value: data['totalCompost'].toStringAsFixed(0),
                              unit: 'kg',
                              subtitle: 'Total Produced',
                              icon: Icons.eco,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 16),
                          // Right Box - Contributors
                          Expanded(
                            child: _buildStatBox(
                              title: 'Contributors',
                              value: data['activeContributors'].toString(),
                              unit: '',
                              subtitle: 'Active this month',
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Second Row - Two Boxes
                      Row(
                        children: [
                          // Left Box - Deliveries
                          Expanded(
                            child: _buildStatBox(
                              title: 'Deliveries',
                              value: data['scheduledDeliveries'].toString(),
                              unit: '',
                              subtitle: 'Scheduled this week',
                              icon: Icons.local_shipping,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(width: 16),
                          // Right Box - CO2 Saved
                          Expanded(
                            child: _buildStatBox(
                              title: 'CO2 Saved',
                              value: data['co2Saved'].toStringAsFixed(0),
                              unit: 'kg',
                              subtitle: 'Environment impact',
                              icon: Icons.cloud_done,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              
              // Inventory Status
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      StreamBuilder<Map<String, dynamic>>(
                        stream: _getInventoryData(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final data = snapshot.data!;
                          return _buildInventoryItem(
                            'General Purpose Compost',
                            data['current'].toString(),
                            data['total'].toString(),
                            'kg',
                            Colors.green,
                          );
                        },
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

  Widget _buildStatBox({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryItem(
    String name,
    String current,
    String total,
    String unit,
    Color color,
  ) {
    final progress = double.parse(current) / double.parse(total);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            Text(
              '$current/$total $unit',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }
} 