import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class FertilizerLogsScreen extends StatelessWidget {
  Stream<Map<String, num>> _getProductionData() {
    // Create streams for both collections
    final wasteStream = FirebaseFirestore.instance
        .collection('waste_logs')
        .where('status', isEqualTo: 'processed')
        .snapshots();

    final deliveryStream = FirebaseFirestore.instance
        .collection('fertilizer_requests')
        .where('status', isEqualTo: 'delivered')
        .snapshots();

    // Combine both streams
    return Rx.combineLatest2(
      wasteStream,
      deliveryStream,
      (QuerySnapshot wasteLogs, QuerySnapshot deliveries) {
        num totalProduced = 0;
        for (var doc in wasteLogs.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalProduced += data['weight'] as num? ?? 0;
        }

        num totalDelivered = 0;
        for (var doc in deliveries.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalDelivered += data['quantity'] as num? ?? 0;
        }

        return {
          'produced': totalProduced,
          'delivered': totalDelivered,
          'available': totalProduced - totalDelivered,
        };
      },
    );
  }

  Widget _buildProductionOverview() {
    return StreamBuilder<Map<String, num>>(
      stream: _getProductionData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {'produced': 0, 'delivered': 0, 'available': 0};
        
        return Row(
          children: [
            Expanded(
              child: _buildOverviewBox(
                context,
                'Total Produced',
                data['produced']!,
                Icons.inventory,
                Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildOverviewBox(
                context,
                'Delivered',
                data['delivered']!,
                Icons.local_shipping,
                Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildOverviewBox(
                context,
                'Available',
                data['available']!,
                Icons.warehouse,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fertilizer Logs',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Track compost usage and distribution',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                
                // Production Overview
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Production Overview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        _buildProductionOverview(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // Recent Transactions
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _getTransactionsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final transactions = snapshot.data?.docs ?? [];
                    
                    if (transactions.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No transactions available'),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index].data() as Map<String, dynamic>;
                        final timestamp = transaction['timestamp'] as Timestamp;
                        final status = transaction['status'] as String? ?? 'pending';
                        final deliveryDate = (transaction['deliveryDate'] as Timestamp?)?.toDate();
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: _buildStatusIcon(status),
                            title: Text(
                              'Request by ${transaction['farmerName'] ?? 'Unknown Farmer'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  '${transaction['quantity']}kg • ${transaction['farmLocationName'] ?? 'Unknown Location'}',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2),
                                if (deliveryDate != null)
                                  Text(
                                    'Delivery: ${DateFormat('MMM d, y').format(deliveryDate)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                Text(
                                  'Requested: ${DateFormat('MMM d, y').format(timestamp.toDate())}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: _buildStatusChip(status),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewBox(
    BuildContext context,
    String title,
    num value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(0)}kg',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color color;
    
    switch (status.toLowerCase()) {
      case 'delivered':
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case 'processing':
        iconData = Icons.pending;
        color = Colors.blue;
        break;
      case 'scheduled':
        iconData = Icons.schedule;
        color = Colors.orange;
        break;
      case 'cancelled':
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      default:
        iconData = Icons.fiber_new;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text = status.toUpperCase();
    
    switch (status.toLowerCase()) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'processing':
        color = Colors.blue;
        break;
      case 'scheduled':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    return FirebaseFirestore.instance
        .collection('fertilizer_requests')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }
} 