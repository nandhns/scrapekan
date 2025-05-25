import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../scripts/seed_machine_data.dart';
import '../../config/app_config.dart';

class MachineMonitoringScreen extends StatefulWidget {
  @override
  _MachineMonitoringScreenState createState() => _MachineMonitoringScreenState();
}

class _MachineMonitoringScreenState extends State<MachineMonitoringScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('machines').snapshots(),
          builder: (context, machinesSnapshot) {
            if (machinesSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading machines',
                      style: TextStyle(color: Colors.red),
                    ),
                    if (AppConfig.isDevelopment)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          machinesSnapshot.error.toString(),
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            }

            if (!machinesSnapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Loading machines...'),
                  ],
                ),
              );
            }

            if (machinesSnapshot.data!.docs.isEmpty) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 32),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.precision_manufacturing_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No machines found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          if (AppConfig.isDevelopment)
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final seeder = MachineDataSeeder();
                                  await seeder.seedMachineData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Machine data seeded successfully')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error seeding data: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.add),
                              label: Text('Add Test Machines'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show the actual content when data is available
            return SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  
                  // Machine Status Cards
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('machines').snapshots(),
                    builder: (context, machinesSnapshot) {
                      if (machinesSnapshot.hasError) {
                        return Center(child: Text('Error loading machines'));
                      }

                      if (!machinesSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      return Column(
                        children: machinesSnapshot.data!.docs.map((machineDoc) {
                          final machineData = machineDoc.data() as Map<String, dynamic>;
                          return StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('machine_monitoring')
                                .where('machineId', isEqualTo: machineDoc.id)
                                .orderBy('timestamp', descending: true)
                                .limit(1)
                                .snapshots(),
                            builder: (context, monitoringSnapshot) {
                              if (!monitoringSnapshot.hasData) {
                                return SizedBox();
                              }

                              final monitoringData = monitoringSnapshot.data!.docs.isNotEmpty
                                  ? monitoringSnapshot.data!.docs.first.data() as Map<String, dynamic>
                                  : null;

                              if (monitoringData == null) {
                                return SizedBox();
                              }

                              final isOperating = monitoringData['isOperating'] as bool;
                              final temperature = monitoringData['temperature'] as double;
                              final moisture = monitoringData['moisture'] as double;
                              final currentCapacity = monitoringData['currentCapacity'] as double;
                              final processingStatus = monitoringData['processingStatus'] as double;
                              final maxCapacity = machineData['capacity'] as double;

                              return Column(
                                children: [
                                  _buildMachineStatusCard(
                                    machineName: machineData['name'] as String,
                                    status: isOperating ? 'Operating normally' : 'Maintenance Required',
                                    statusColor: isOperating ? Colors.green : Colors.red,
                                    metrics: [
                                      _MachineMetric(
                                        'Temperature',
                                        '${temperature.toStringAsFixed(1)}°C',
                                        temperature / 100,
                                        temperature > 70 ? 'High' : temperature < 40 ? 'Low' : 'Normal',
                                        temperature > 70 ? Colors.red : temperature < 40 ? Colors.blue : Colors.orange,
                                        '40°C - 70°C',
                                      ),
                                      _MachineMetric(
                                        'Moisture',
                                        '${moisture.toStringAsFixed(1)}%',
                                        moisture / 100,
                                        moisture > 60 ? 'High' : moisture < 30 ? 'Low' : 'Normal',
                                        moisture > 60 ? Colors.red : moisture < 30 ? Colors.orange : Colors.blue,
                                        '30% - 60%',
                                      ),
                                      _MachineMetric(
                                        'Capacity',
                                        '${(currentCapacity / maxCapacity * 100).toStringAsFixed(1)}%',
                                        currentCapacity / maxCapacity,
                                        currentCapacity > maxCapacity * 0.9 ? 'Full' : 'Good',
                                        currentCapacity > maxCapacity * 0.9 ? Colors.red : Colors.green,
                                        '${currentCapacity.toStringAsFixed(0)}kg/${maxCapacity.toStringAsFixed(0)}kg',
                                      ),
                                      _MachineMetric(
                                        'Processing',
                                        '${processingStatus.toStringAsFixed(1)}%',
                                        processingStatus / 100,
                                        processingStatus > 0 ? 'Active' : 'Stopped',
                                        processingStatus > 0 ? Colors.purple : Colors.red,
                                        isOperating ? 'Running' : 'Maintenance',
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24),
                                ],
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  
                  // Maintenance Schedule
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('machines').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      return Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maintenance Schedule',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ...snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final nextMaintenance = (data['nextMaintenance'] as Timestamp).toDate();
                                final daysUntil = nextMaintenance.difference(DateTime.now()).inDays;
                                
                                return Column(
                                  children: [
                                    _buildMaintenanceItem(
                                      data['name'] as String,
                                      'Regular maintenance check',
                                      daysUntil <= 0 ? 'High priority' : 'Normal priority',
                                      daysUntil <= 0 ? Colors.red : Colors.blue,
                                      daysUntil <= 0 ? 'Due today' : 'Due in $daysUntil days',
                                    ),
                                    if (doc.id != snapshot.data!.docs.last.id) Divider(),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  
                  // Maintenance Alerts
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('maintenance_alerts')
                        .where('status', isEqualTo: 'OPEN')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return Card(
                          elevation: 4,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maintenance Alerts',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'No active alerts',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maintenance Alerts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ...snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final timestamp = (data['timestamp'] as Timestamp).toDate();
                                final hoursAgo = DateTime.now().difference(timestamp).inHours;
                                
                                return Column(
                                  children: [
                                    _buildAlertItem(
                                      data['machineId'] as String,
                                      data['message'] as String,
                                      data['type'] as String,
                                      data['type'] == 'CRITICAL' ? Colors.red : Colors.orange,
                                      '$hoursAgo hours ago',
                                    ),
                                    if (doc.id != snapshot.data!.docs.last.id) Divider(),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compost Machine Monitoring',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Monitor and manage compost machine operations',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (AppConfig.isDevelopment)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final seeder = MachineDataSeeder();
                await seeder.seedMachineData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Machine data seeded successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error seeding data: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: Icon(Icons.data_array),
            label: Text('Seed Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildMachineStatusCard({
    required String machineName,
    required String status,
    required Color statusColor,
    required List<_MachineMetric> metrics,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machineName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
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
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement configure functionality
                  },
                  icon: Icon(Icons.settings),
                  label: Text('Configure'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Machine Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: metrics.map((metric) => _buildMetricCard(
                context,
                metric.title,
                metric.value,
                metric.progress,
                metric.status,
                metric.color,
                metric.subtitle,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    double progress,
    String status,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
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

  Widget _buildMaintenanceItem(
    String machine,
    String task,
    String priority,
    Color priorityColor,
    String dueDate,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(task),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                dueDate,
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

  Widget _buildAlertItem(
    String machine,
    String message,
    String severity,
    Color severityColor,
    String time,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
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
}

class _MachineMetric {
  final String title;
  final String value;
  final double progress;
  final String status;
  final Color color;
  final String subtitle;

  _MachineMetric(
    this.title,
    this.value,
    this.progress,
    this.status,
    this.color,
    this.subtitle,
  );
} 