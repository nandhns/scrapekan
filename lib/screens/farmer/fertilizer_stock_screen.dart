import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class FertilizerStockScreen extends StatefulWidget {
  @override
  _FertilizerStockScreenState createState() => _FertilizerStockScreenState();
}

class _FertilizerStockScreenState extends State<FertilizerStockScreen> {
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = authService.currentUser?.uid;
  }

  Stream<Map<String, dynamic>> _getStockStream() {
    // Calculate total produced and delivered fertilizer
    return FirebaseFirestore.instance
        .collection('waste_logs')
        .snapshots()
        .asyncMap((wasteLogs) async {
          double totalProduced = 0;
          
          // Calculate total produced (30% of waste weight becomes fertilizer)
          for (var doc in wasteLogs.docs) {
            final data = doc.data();
            if (data.containsKey('weight')) {
              totalProduced += (data['weight'] as num).toDouble() * 0.3;
            }
          }

          // Get total delivered from fertilizer requests
          final deliveredSnapshot = await FirebaseFirestore.instance
              .collection('fertilizer_requests')
              .where('status', isEqualTo: 'delivered')
              .get();

          double totalDelivered = 0;
          for (var doc in deliveredSnapshot.docs) {
            final data = doc.data();
            if (data.containsKey('quantity')) {
              totalDelivered += (data['quantity'] as num).toDouble();
            }
          }

          // Available stock is produced minus delivered
          return {
            'totalProduced': totalProduced,
            'totalDelivered': totalDelivered,
            'available': totalProduced - totalDelivered
          };
        });
  }

  Stream<QuerySnapshot> _getDeliveriesStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return FirebaseFirestore.instance
        .collection('fertilizer_requests')
        .where('status', whereIn: ['pending', 'confirmed', 'in_transit'])
        .where('deliveryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('deliveryDate', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text('Please log in to view fertilizer stock'));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fertilizer Stock',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your fertilizer production and deliveries',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stock Overview
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stock',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<Map<String, dynamic>>(
                          stream: _getStockStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final data = snapshot.data!;
                            
                            return Column(
                              children: [
                                _buildStockItem(
                                  context,
                                  'Total Produced',
                                  data['totalProduced'] ?? 0,
                                  'kg',
                                  Colors.green,
                                ),
                                const SizedBox(height: 12),
                                _buildStockItem(
                                  context,
                                  'Total Delivered',
                                  data['totalDelivered'] ?? 0,
                                  'kg',
                                  Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                _buildStockItem(
                                  context,
                                  'Available Stock',
                                  data['available'] ?? 0,
                                  'kg',
                                  Theme.of(context).primaryColor,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Upcoming Deliveries
                Text(
                  'Upcoming Deliveries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _getDeliveriesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final deliveries = snapshot.data?.docs ?? [];
                    
                    if (deliveries.isEmpty) {
                      return const Center(
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
                        final status = data['status'] as String? ?? 'pending';
                        final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
                        final farmerId = data['farmerId'] as String? ?? '';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                const SizedBox(height: 4),
                                Text(
                                  'Organic Compost • ${quantity.toStringAsFixed(1)}kg',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (farmerId.isNotEmpty)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(farmerId)
                                        .get(),
                                    builder: (context, farmerSnapshot) {
                                      String farmerName = 'Unknown Farmer';
                                      if (farmerSnapshot.hasData && farmerSnapshot.data != null) {
                                        final farmerData = farmerSnapshot.data!.data() as Map<String, dynamic>?;
                                        farmerName = farmerData?['name'] as String? ?? 'Unknown Farmer';
                                      }
                                      return Text(
                                        farmerName,
                                        style: TextStyle(color: Colors.grey[600]),
                                      );
                                    },
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

  Widget _buildStockItem(BuildContext context, String name, num quantity, String unit, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${quantity.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
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
} 