import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  @override
  _DeliveryConfirmationScreenState createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _deliveryEvents = {};

  @override
  void initState() {
    super.initState();
    _loadDeliveryEvents();
  }

  void _loadDeliveryEvents() {
    FirebaseFirestore.instance
        .collection('fertilizer_requests')
        .where('status', whereIn: ['pending', 'confirmed'])
        .get()
        .then((snapshot) {
      final Map<DateTime, List<dynamic>> events = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final deliveryDate = (data['deliveryDate'] as Timestamp?)?.toDate();
        
        if (deliveryDate != null) {
          final day = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
          if (!events.containsKey(day)) {
            events[day] = [];
          }
          
          events[day]!.add({
            'id': doc.id,
            'location': data['farmLocation'] ?? 'Unknown Location',
            'farmer': data['farmerName'] ?? 'Unknown Farmer',
            'quantity': data['quantity']?.toString() ?? '0',
            'status': data['status'] ?? 'pending'
          });
        }
      }
      
      setState(() {
        _deliveryEvents = events;
      });
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _deliveryEvents[normalizedDay] ?? [];
  }

  Widget _buildEventList(List<dynamic> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events.map((event) {
        final status = event['status'] as String;
        final statusColor = status == 'confirmed' ? Colors.green : Colors.orange;
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${event['location']} (${event['quantity']}kg)',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      children: [
        Icon(
          Icons.calendar_month,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        SizedBox(width: 12),
        Text(
          'Delivery Calendar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<DateTime>(
            value: DateTime(_focusedDay.year, _focusedDay.month),
            items: List.generate(12, (index) {
              final date = DateTime(
                _focusedDay.year,
                _focusedDay.month - (_focusedDay.month - 1 - index),
              );
              return DropdownMenuItem(
                value: date,
                child: Text(
                  DateFormat('MMMM yyyy').format(date),
                  style: TextStyle(fontSize: 14),
                ),
              );
            }),
            onChanged: (date) {
              if (date != null) {
                setState(() {
                  _focusedDay = date;
                });
              }
            },
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
          ),
        ),
      ],
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
                  'Delivery Confirmation',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Confirm and track fertilizer deliveries',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                
                // Pending Deliveries
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Deliveries',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: _getPendingDeliveriesStream(),
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
                                  child: Text('No pending deliveries'),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: deliveries.length,
                              itemBuilder: (context, index) {
                                final delivery = deliveries[index].data() as Map<String, dynamic>;
                                final timestamp = delivery['timestamp'] as Timestamp;
                                
                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(delivery['farmerName'] ?? 'Unknown Farmer'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          '${delivery['quantity']}kg • ${delivery['farmLocation']}',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Requested: ${DateFormat('MMM d, y').format(timestamp.toDate())}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check_circle, color: Colors.green),
                                          onPressed: () => _confirmDelivery(context, deliveries[index].id),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.cancel, color: Colors.red),
                                          onPressed: () => _rejectDelivery(context, deliveries[index].id),
                                        ),
                                      ],
                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getPendingDeliveriesStream() {
    return FirebaseFirestore.instance
        .collection('fertilizer_deliveries')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _confirmDelivery(BuildContext context, String deliveryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('fertilizer_deliveries')
          .doc(deliveryId)
          .update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery confirmed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming delivery: $e')),
      );
    }
  }

  Future<void> _rejectDelivery(BuildContext context, String deliveryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('fertilizer_deliveries')
          .doc(deliveryId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting delivery: $e')),
      );
    }
  }
} 