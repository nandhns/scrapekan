import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/waste_service.dart';
import '../services/notification_service.dart';
import '../providers/service_provider.dart';
import '../models/firestore_schema.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = 'This Month';
  late final WasteService _wasteService;
  late final NotificationService _notificationService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wasteService = ServiceProvider.of(context).wasteService;
    _notificationService = ServiceProvider.of(context).notificationService;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My Impact Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your contribution to sustainability',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          // Period Selector
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Contributions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    items: ['This Month', 'Last Month', 'This Year']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                        });
                      }
                    },
                    underline: Container(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Impact Metrics
          StreamBuilder<List<WasteLog>>(
            stream: _wasteService.getUserWasteHistory(_wasteService.currentUserId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final logs = snapshot.data!;
              double totalWaste = 0;
              double totalCompost = 0;
              double co2Saved = 0;

              for (var log in logs) {
                if (log.status == 'verified' || log.status == 'composted') {
                  totalWaste += log.weight;
                  if (log.status == 'composted') {
                    totalCompost += log.weight * 0.3; // Assuming 30% compost yield
                    co2Saved += log.weight * 0.5; // Assuming 0.5kg CO2 saved per kg waste
                  }
                }
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Waste Dropped',
                      totalWaste.toStringAsFixed(1),
                      'kg',
                      Icons.delete_outline,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Compost Created',
                      totalCompost.toStringAsFixed(1),
                      'kg',
                      Icons.eco,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'CO2 Saved',
                      co2Saved.toStringAsFixed(1),
                      'kg',
                      Icons.cloud_done,
                      Colors.blue,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24),

          // Recent Activity
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<List<WasteLog>>(
                    stream: _wasteService.getUserWasteHistory(_wasteService.currentUserId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final recentLogs = snapshot.data!.take(3).toList();

                      return Column(
                        children: recentLogs.map((log) {
                          return Column(
                            children: [
                              _buildActivityItem(
                                'Dropped off organic waste',
                                log.dropOffPointId,
                                '${log.weight} kg',
                                log.timestamp,
                              ),
                              if (recentLogs.last != log) Divider(),
                            ],
                          );
                        }).toList(),
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

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
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

  Widget _buildActivityItem(
    String title,
    String location,
    String amount,
    DateTime time,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco,
              color: Colors.green,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                FutureBuilder<DocumentSnapshot>(
                  future: _wasteService.dropoffPointsRef.doc(location).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text(location);
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    return Text(
                      data['name'] ?? location,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _getTimeAgo(time),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double progress;
  final String level;

  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.progress,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
          ),
          SizedBox(height: 4),
          Text(level),
        ],
      ),
    );
  }
} 