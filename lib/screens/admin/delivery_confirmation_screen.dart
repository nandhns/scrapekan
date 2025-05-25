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
        .orderBy('deliveryDate', descending: false)
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
            'location': data['farmLocationName'] ?? 'Unknown Location',
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
                  'Delivery Management',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Schedule and confirm fertilizer deliveries',
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
                                final deliveryDate = (delivery['deliveryDate'] as Timestamp?)?.toDate();
                                
                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      'Request by ${delivery['farmerName'] ?? 'Unknown Farmer'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          '${delivery['quantity']}kg • ${delivery['farmLocationName']}',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        if (deliveryDate != null)
                                          Text(
                                            'Delivery Date: ${DateFormat('MMM d, y').format(deliveryDate)}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.check_circle, size: 18),
                                          label: Text('Confirm'),
                                          onPressed: () => _confirmDelivery(context, deliveries[index].id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          icon: Icon(Icons.calendar_month, size: 18),
                                          label: Text('Reschedule'),
                                          onPressed: () => _showRescheduleDialog(context, deliveries[index].id, deliveryDate),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Theme.of(context).primaryColor,
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                          ),
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
                SizedBox(height: 24),

                // Delivery Calendar
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCalendarHeader(),
                        SizedBox(height: 16),
                        TableCalendar(
                          firstDay: DateTime.now().subtract(Duration(days: 365)),
                          lastDay: DateTime.now().add(Duration(days: 365)),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarStyle: CalendarStyle(
                            markersMaxCount: 3,
                            markerDecoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        if (_selectedDay != null && _getEventsForDay(_selectedDay!).isNotEmpty) ...[
                          SizedBox(height: 16),
                          Text(
                            'Deliveries on ${DateFormat('MMM d, y').format(_selectedDay!)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          _buildEventList(_getEventsForDay(_selectedDay!)),
                        ],
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
        .collection('fertilizer_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('deliveryDate', descending: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _confirmDelivery(BuildContext context, String deliveryId) async {
    try {
      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();
      
      // Get the request document
      final requestDoc = await FirebaseFirestore.instance
          .collection('fertilizer_requests')
          .doc(deliveryId)
          .get();

      if (!requestDoc.exists) {
        throw 'Request not found';
      }

      final requestData = requestDoc.data()!;
      final farmerId = requestData['farmerId'];
      final quantity = requestData['quantity'];

      // Update the request status
      batch.update(
        FirebaseFirestore.instance.collection('fertilizer_requests').doc(deliveryId),
        {
          'status': 'delivered',
          'confirmedAt': FieldValue.serverTimestamp(),
          'deliveredAt': FieldValue.serverTimestamp(),
          'deliveredQuantity': quantity,
        }
      );

      // Create a notification for the farmer
      final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': farmerId,
        'type': 'REQUEST_APPROVED',
        'title': 'Fertilizer Delivery Completed',
        'message': 'Your request for ${quantity}kg of fertilizer has been delivered.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'requestId': deliveryId
      });

      // Commit the batch
      await batch.commit();

      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery confirmed and marked as delivered'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error confirming delivery: $e');
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming delivery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRescheduleDialog(BuildContext context, String deliveryId, DateTime? currentDate) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      helpText: 'Select New Delivery Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      try {
        // Start a batch write
        final batch = FirebaseFirestore.instance.batch();

        // Get the request document
        final requestDoc = await FirebaseFirestore.instance
            .collection('fertilizer_requests')
            .doc(deliveryId)
            .get();

        if (!requestDoc.exists) {
          throw 'Request not found';
        }

        final requestData = requestDoc.data()!;
        final farmerId = requestData['farmerId'];

        // Update the request
        batch.update(
          FirebaseFirestore.instance.collection('fertilizer_requests').doc(deliveryId),
          {
            'deliveryDate': Timestamp.fromDate(selectedDate),
            'rescheduledAt': FieldValue.serverTimestamp(),
          }
        );

        // Create a notification for the farmer
        final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': farmerId,
          'type': 'DELIVERY_SCHEDULED',
          'title': 'Delivery Rescheduled',
          'message': 'Your delivery has been rescheduled to ${DateFormat('MMM d, y').format(selectedDate)}.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'requestId': deliveryId
        });

        // Commit the batch
        await batch.commit();

        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error rescheduling delivery: $e');
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 