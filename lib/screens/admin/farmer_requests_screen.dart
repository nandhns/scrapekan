import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FarmerRequestsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmer Requests',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage and approve fertilizer requests',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            
            // Pending Approvals Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Pending Approvals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('fertilizer_requests')
                        .where('status', isEqualTo: 'pending')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error loading requests');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final requests = snapshot.data?.docs ?? [];

                      if (requests.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No pending requests',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: requests.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp = data['timestamp'] as Timestamp;
                          final date = timestamp.toDate();

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['farmLocation'] ?? 'Location not specified',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Farmer: ${data['farmerName'] ?? 'Not specified'}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${data['compostName'] ?? 'General Purpose Compost'} - ${data['quantity']?.toString() ?? '0'} kg',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Requested for: ${DateFormat('MMM d, y').format(date)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          _rejectRequest(context, doc.id);
                                        },
                                        child: Text('Reject'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          _approveRequest(context, doc.id);
                                        },
                                        child: Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
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
            
            SizedBox(height: 24),
            
            // Recently Processed Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Recently Processed',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('fertilizer_requests')
                        .where('status', whereIn: ['approved', 'rejected'])
                        .orderBy('timestamp', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error loading processed requests');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final requests = snapshot.data?.docs ?? [];

                      if (requests.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No processed requests',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: requests.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final processedTimestamp = data['processedTimestamp'] as Timestamp?;
                          final timestamp = data['timestamp'] as Timestamp;
                          final processedDate = processedTimestamp?.toDate() ?? timestamp.toDate();

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        data['farmLocation'] ?? 'Location not specified',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      _buildStatusChip(data['status'] ?? 'unknown'),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Farmer: ${data['farmerName'] ?? 'Not specified'}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${data['compostName'] ?? 'General Purpose Compost'} - ${data['quantity']?.toString() ?? '0'} kg',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Processed on: ${DateFormat('MMM d, y HH:mm').format(processedDate)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (data['status'] == 'rejected' && data['rejectionReason'] != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Reason: ${data['rejectionReason']}',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
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

  Future<void> _approveRequest(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('fertilizer_requests')
          .doc(requestId)
          .update({
        'status': 'approved',
        'processedTimestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requestId) async {
    String? reason;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Request'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter the reason for rejecting this request',
          ),
          onChanged: (value) => reason = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (reason?.isNotEmpty ?? false) {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance
                      .collection('fertilizer_requests')
                      .doc(requestId)
                      .update({
                    'status': 'rejected',
                    'rejectionReason': reason,
                    'processedTimestamp': FieldValue.serverTimestamp(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Request rejected')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rejecting request: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please provide a reason for rejection')),
                );
              }
            },
            child: Text('Reject'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
} 