import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MachineMonitoringScreen extends StatefulWidget {
  @override
  _MachineMonitoringScreenState createState() => _MachineMonitoringScreenState();
}

class _MachineMonitoringScreenState extends State<MachineMonitoringScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              SizedBox(height: 24),
              
              // Machine 01 Status
              _buildMachineStatusCard(
                machineName: 'Machine 01 - Pasar Tani Kekal Pekan',
                status: 'Operating normally',
                statusColor: Colors.green,
                metrics: [
                  _MachineMetric('Temperature', '65°C', 0.65, 'Normal', Colors.orange, '40°C - 70°C'),
                  _MachineMetric('Moisture', '45%', 0.45, 'Normal', Colors.blue, '30% - 60%'),
                  _MachineMetric('Capacity', '75%', 0.75, 'Good', Colors.green, '150kg/200kg'),
                  _MachineMetric('Processing', '80%', 0.80, 'Active', Colors.purple, 'Batch #245'),
                ],
              ),
              SizedBox(height: 24),
              
              // Machine 02 Status (Requires Maintenance)
              _buildMachineStatusCard(
                machineName: 'Machine 02 - Pasar Tani Kekal Pekan',
                status: 'Maintenance Required',
                statusColor: Colors.red,
                metrics: [
                  _MachineMetric('Temperature', '85°C', 0.85, 'High', Colors.red, '40°C - 70°C'),
                  _MachineMetric('Moisture', '25%', 0.25, 'Low', Colors.orange, '30% - 60%'),
                  _MachineMetric('Capacity', '90%', 0.90, 'Full', Colors.blue, '180kg/200kg'),
                  _MachineMetric('Processing', '0%', 0.0, 'Stopped', Colors.red, 'Maintenance'),
                ],
              ),
              SizedBox(height: 24),
              
              // Maintenance Schedule
              _buildMaintenanceSchedule(),
              SizedBox(height: 24),
              
              // Maintenance Alerts
              _buildMaintenanceAlerts(),
            ],
          ),
        ),
      ),
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

  Widget _buildMaintenanceSchedule() {
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
            _buildMaintenanceItem(
              'Machine 02 - Pasar Tani Kekal Pekan',
              'Temperature sensor calibration',
              'High priority',
              Colors.red,
              'Due today',
            ),
            Divider(),
            _buildMaintenanceItem(
              'Machine 01 - Pasar Tani Kekal Pekan',
              'Regular maintenance check',
              'Normal priority',
              Colors.blue,
              'Due in 5 days',
            ),
          ],
        ),
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

  Widget _buildMaintenanceAlerts() {
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
            _buildAlertItem(
              'Machine 02 - Pasar Tani Kekal Pekan',
              'Temperature sensor malfunction detected',
              'Critical',
              Colors.red,
              '2 hours ago',
            ),
            Divider(),
            _buildAlertItem(
              'Machine 02 - Pasar Tani Kekal Pekan',
              'Moisture levels below normal range',
              'Warning',
              Colors.orange,
              '3 hours ago',
            ),
          ],
        ),
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