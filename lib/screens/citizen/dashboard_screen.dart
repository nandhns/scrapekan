import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/waste_log.dart';

class CitizenDashboardScreen extends StatefulWidget {
  @override
  _CitizenDashboardScreenState createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Impact Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your contribution to sustainability',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Impact Metrics
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('waste_logs')
                .where('userId', isEqualTo: user.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final logs = snapshot.data!.docs;
              double totalWaste = 0;
              double totalCompost = 0;
              double co2Saved = 0;

              for (var doc in logs) {
                final log = WasteLog.fromFirestore(doc);
                totalWaste += log.weight;
                totalCompost += log.weight * 0.3; // Assuming 30% compost yield
                co2Saved += log.weight * 0.5; // Assuming 0.5kg CO2 saved per kg waste
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Waste',
                      '${totalWaste.toStringAsFixed(1)} kg',
                      Icons.delete_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Composted',
                      '${totalCompost.toStringAsFixed(1)} kg',
                      Icons.eco,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'CO₂ Saved',
                      '${co2Saved.toStringAsFixed(1)} kg',
                      Icons.cloud_done,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('waste_logs')
                        .where('userId', isEqualTo: user.id)
                        .orderBy('timestamp', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final logs = snapshot.data!.docs;

                      if (logs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No activity yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logs.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final log = WasteLog.fromFirestore(logs[index]);

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('dropoff_points').doc(log.dropOffPointId).get(),
                            builder: (context, locationSnapshot) {
                              String locationName = 'Unknown Location';
                              
                              if (locationSnapshot.hasData && locationSnapshot.data != null) {
                                final locationData = locationSnapshot.data!.data() as Map<String, dynamic>?;
                                locationName = locationData?['name'] as String? ?? 'Unknown Location';
                              }

                              return ListTile(
                                leading: const Icon(Icons.eco, color: Colors.green),
                                title: Text('${log.weight} kg ${log.wasteType}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(locationName),
                                    Text(
                                      _getTimeAgo(log.timestamp),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
    );
  }
} 