import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MachineMonitoringScreen extends StatefulWidget {
  @override
  _MachineMonitoringScreenState createState() => _MachineMonitoringScreenState();
}

class _MachineMonitoringScreenState extends State<MachineMonitoringScreen> {
  String _selectedMachine = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Machine Monitoring')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMachineSelector(),
            SizedBox(height: 24),
            _buildStatusOverview(),
            SizedBox(height: 24),
            _buildPerformanceMetrics(),
            SizedBox(height: 24),
            _buildMaintenanceAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Machine',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('machines')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final machines = snapshot.data?.docs ?? [];
                final items = [
                  DropdownMenuItem(value: 'all', child: Text('All Machines')),
                  ...machines.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name']),
                    );
                  }),
                ];

                return DropdownButtonFormField<String>(
                  value: _selectedMachine,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: items,
                  onChanged: (value) {
                    setState(() => _selectedMachine = value!);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMachinesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final machines = snapshot.data?.docs ?? [];
        final stats = _calculateStats(machines);

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'Operational',
                        stats['operational'].toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        'Maintenance',
                        stats['maintenance'].toString(),
                        Icons.build,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        'Offline',
                        stats['offline'].toString(),
                        Icons.error,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: _getMachineMetricsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final metrics = snapshot.data?.docs ?? [];
                  final data = _processMetricsData(metrics);

                  return data.spots.isEmpty
                      ? Center(child: Text('No data available'))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < data.labels.length) {
                                      return Text(
                                        data.labels[value.toInt()],
                                        style: TextStyle(fontSize: 10),
                                      );
                                    }
                                    return Text('');
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: data.spots,
                                isCurved: true,
                                color: Theme.of(context).primaryColor,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMaintenanceAlertsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final alerts = snapshot.data?.docs ?? [];

        if (alerts.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No maintenance alerts'),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenance Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                ...alerts.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp;
                  final date = timestamp.toDate();

                  return ListTile(
                    leading: Icon(
                      _getAlertIcon(data['severity']),
                      color: _getAlertColor(data['severity']),
                    ),
                    title: Text(data['title']),
                    subtitle: Text(
                      'Machine: ${data['machineName']}\n'
                      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                    ),
                    isThreeLine: true,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getMachinesStream() {
    var query = FirebaseFirestore.instance.collection('machines').snapshots();
    if (_selectedMachine != 'all') {
      return FirebaseFirestore.instance
          .collection('machines')
          .where(FieldPath.documentId, isEqualTo: _selectedMachine)
          .snapshots();
    }
    return query;
  }

  Stream<QuerySnapshot> _getMachineMetricsStream() {
    var query = FirebaseFirestore.instance.collection('machine_metrics');
    if (_selectedMachine != 'all') {
      return query
          .where('machineId', isEqualTo: _selectedMachine)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots();
    }
    return query
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots();
  }

  Stream<QuerySnapshot> _getMaintenanceAlertsStream() {
    var query = FirebaseFirestore.instance.collection('maintenance_alerts');
    if (_selectedMachine != 'all') {
      return query
          .where('machineId', isEqualTo: _selectedMachine)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots();
    }
    return query
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> machines) {
    int operational = 0;
    int maintenance = 0;
    int offline = 0;

    for (var doc in machines) {
      final data = doc.data() as Map<String, dynamic>;
      switch (data['status']) {
        case 'operational':
          operational++;
          break;
        case 'maintenance':
          maintenance++;
          break;
        case 'offline':
          offline++;
          break;
      }
    }

    return {
      'operational': operational,
      'maintenance': maintenance,
      'offline': offline,
    };
  }

  ChartData _processMetricsData(List<QueryDocumentSnapshot> metrics) {
    Map<String, double> dailyData = {};

    for (var doc in metrics.reversed) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateStr = '${date.day}/${date.month}';
      final efficiency = (data['efficiency'] as num).toDouble();

      if (dailyData.containsKey(dateStr)) {
        dailyData[dateStr] = (dailyData[dateStr]! + efficiency) / 2;
      } else {
        dailyData[dateStr] = efficiency;
      }
    }

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ChartData(
      spots: List.generate(
        sortedEntries.length,
        (index) => FlSpot(index.toDouble(), sortedEntries[index].value),
      ),
      labels: sortedEntries.map((e) => e.key).toList(),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAlertIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.info;
      default:
        return Icons.info;
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class ChartData {
  final List<FlSpot> spots;
  final List<String> labels;

  ChartData({required this.spots, required this.labels});
} 