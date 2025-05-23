import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FertilizerLogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Fertilizer Logs'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Recent'),
              Tab(text: 'Statistics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RecentLogsTab(),
            _StatisticsTab(),
          ],
        ),
      ),
    );
  }
}

class _RecentLogsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fertilizer_requests')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data?.docs ?? [];

        if (logs.isEmpty) {
          return Center(child: Text('No logs available'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final timestamp = log['timestamp'] as Timestamp;
            final deliveryDate = log['deliveryDate'] as Timestamp?;

            return Card(
              child: ListTile(
                leading: Icon(
                  _getStatusIcon(log['status']),
                  color: _getStatusColor(log['status']),
                ),
                title: Text(
                  '${log['fertilizerType']} - ${log['quantity']} kg',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Requested: ${_formatDate(timestamp.toDate())}'),
                    if (deliveryDate != null)
                      Text('Delivered: ${_formatDate(deliveryDate.toDate())}'),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log['status']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log['status'].toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(log['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class _StatisticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('fertilizer_requests')
          .where('status', isEqualTo: 'delivered')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data?.docs ?? [];
        final stats = _calculateStats(logs);

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCard(
                'Total Deliveries',
                stats['totalDeliveries'].toString(),
                Icons.local_shipping,
                Colors.blue,
              ),
              SizedBox(height: 16),
              _buildStatCard(
                'Total Quantity',
                '${stats['totalQuantity'].toStringAsFixed(1)} kg',
                Icons.scale,
                Colors.green,
              ),
              SizedBox(height: 16),
              _buildStatCard(
                'Average Quantity',
                '${stats['averageQuantity'].toStringAsFixed(1)} kg',
                Icons.analytics,
                Colors.orange,
              ),
              SizedBox(height: 24),
              Text(
                'Distribution by Type',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              ...stats['typeDistribution'].entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key.toUpperCase()),
                    trailing: Text(
                      '${entry.value.toStringAsFixed(1)} kg',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> logs) {
    int totalDeliveries = logs.length;
    double totalQuantity = 0;
    Map<String, double> typeDistribution = {};

    for (var log in logs) {
      final data = log.data() as Map<String, dynamic>;
      final quantity = data['quantity'] as num;
      final type = data['fertilizerType'] as String;

      totalQuantity += quantity.toDouble();
      typeDistribution[type] = (typeDistribution[type] ?? 0) + quantity.toDouble();
    }

    return {
      'totalDeliveries': totalDeliveries,
      'totalQuantity': totalQuantity,
      'averageQuantity': totalDeliveries > 0 ? totalQuantity / totalDeliveries : 0,
      'typeDistribution': typeDistribution,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 