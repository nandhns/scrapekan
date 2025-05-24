import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FertilizerStockScreen extends StatelessWidget {
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
                  'Fertilizer Stock',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Track your fertilizer deliveries and stock',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                
                // Stock Overview
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stock',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: _getStockStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final stock = snapshot.data?.docs ?? [];
                            
                            if (stock.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No stock data available'),
                                ),
                              );
                            }

                            return Column(
                              children: stock.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildStockItem(
                                  context,
                                  data['name'] as String? ?? 'General Purpose Compost',
                                  data['quantity'] as num? ?? 0,
                                  data['unit'] as String? ?? 'kg',
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // Upcoming Deliveries
                Text(
                  'Upcoming Deliveries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _getDeliveriesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final deliveries = snapshot.data?.docs ?? [];
                    
                    if (deliveries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No upcoming deliveries'),
                        ),
                      );
                    }

                    return Column(
                      children: deliveries.map((delivery) {
                        final data = delivery.data() as Map<String, dynamic>;
                        final deliveryDate = (data['deliveryDate'] as Timestamp).toDate();
                        final status = data['status'] as String;
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          child: ListTile(
                            leading: _getStatusIcon(status),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMM dd, yyyy').format(deliveryDate)),
                                _buildDeliveryStatus(status),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  'General Purpose Compost • ${data['quantity']}kg',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${data['farmLocation']} (Pekan)',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildStockItem(BuildContext context, String name, num quantity, String unit) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Available Stock',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            '$quantity $unit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatus(String status) {
    String displayStatus;
    Color color;
    
    switch (status) {
      case 'confirmed':
        displayStatus = 'Confirmed';
        color = Colors.green;
        break;
      case 'in_transit':
        displayStatus = 'In Transit';
        color = Colors.blue;
        break;
      default:
        displayStatus = 'Pending';
        color = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    IconData iconData;
    Color color;
    
    switch (status) {
      case 'confirmed':
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case 'in_transit':
        iconData = Icons.local_shipping;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.pending;
        color = Colors.orange;
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

  Stream<QuerySnapshot> _getStockStream() {
    return FirebaseFirestore.instance
        .collection('fertilizer_stock')
        .snapshots();
  }

  Stream<QuerySnapshot> _getDeliveriesStream() {
    return FirebaseFirestore.instance
        .collection('fertilizer_deliveries')
        .orderBy('deliveryDate', descending: false)
        .where('deliveryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .limit(10)
        .snapshots();
  }
} 