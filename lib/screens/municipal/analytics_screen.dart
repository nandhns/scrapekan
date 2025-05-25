import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../scripts/seed_fertilizer_requests.dart';
import '../../config/app_config.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'month';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _getRegionalDemandData() async {
    // Get current period start date
    DateTime periodStart = _selectedPeriod == 'month' 
        ? DateTime.now().subtract(Duration(days: 30))
        : DateTime.now().subtract(Duration(days: 7));

    // Get fertilizer requests for the period
    QuerySnapshot currentRequests = await _firestore
        .collection('fertilizer_requests')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(periodStart))
        .get();

    // Get previous period requests for growth calculation
    QuerySnapshot previousRequests = await _firestore
        .collection('fertilizer_requests')
        .where('timestamp', 
            isGreaterThan: Timestamp.fromDate(periodStart.subtract(Duration(days: _selectedPeriod == 'month' ? 30 : 7))),
            isLessThan: Timestamp.fromDate(periodStart))
        .get();

    // Calculate demand by region
    Map<String, double> currentDemand = {};
    Map<String, double> previousDemand = {};
    
    // Process current period
    for (var doc in currentRequests.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final region = data['region'] as String;
      final amount = (data['amount'] as num).toDouble();
      currentDemand[region] = (currentDemand[region] ?? 0) + amount;
    }

    // Process previous period
    for (var doc in previousRequests.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final region = data['region'] as String;
      final amount = (data['amount'] as num).toDouble();
      previousDemand[region] = (previousDemand[region] ?? 0) + amount;
    }

    // Find highest demand region
    String highestDemandRegion = '';
    double highestDemand = 0;
    double totalDemand = 0;

    currentDemand.forEach((region, demand) {
      totalDemand += demand;
      if (demand > highestDemand) {
        highestDemand = demand;
        highestDemandRegion = region;
      }
    });

    // Calculate highest growth rate
    String fastestGrowingRegion = '';
    double highestGrowthRate = 0;

    currentDemand.forEach((region, currentAmount) {
      final previousAmount = previousDemand[region] ?? 0;
      if (previousAmount > 0) {
        final growthRate = (currentAmount - previousAmount) / previousAmount * 100;
        if (growthRate > highestGrowthRate) {
          highestGrowthRate = growthRate;
          fastestGrowingRegion = region;
        }
      }
    });

    return {
      'highestDemand': {
        'region': highestDemandRegion,
        'percentage': (highestDemand / totalDemand * 100).toStringAsFixed(1),
      },
      'fastestGrowing': {
        'region': fastestGrowingRegion,
        'growth': highestGrowthRate.toStringAsFixed(1),
      },
    };
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeader(),
                            _buildPeriodSelector(),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            SizedBox(height: 16),
                            _buildPeriodSelector(),
                          ],
                        );
                  },
                ),
                SizedBox(height: 24),
                
                // Compost Demand by Region
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                            SizedBox(width: 12),
                            Text(
                              'Compost Demand by Region',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getRegionalDemandData(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error loading data'));
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final data = snapshot.data!;
                            final highestDemand = data['highestDemand'];
                            final fastestGrowing = data['fastestGrowing'];

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return constraints.maxWidth > 600
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: _buildDemandCard(
                                              context,
                                              'Highest Demand',
                                              highestDemand['region'],
                                              '${highestDemand['percentage']}%',
                                              'of total requests',
                                              Colors.orange,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: _buildDemandCard(
                                              context,
                                              'Growing Region',
                                              fastestGrowing['region'],
                                              '+${fastestGrowing['growth']}%',
                                              'increase in requests',
                                              Colors.green,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildDemandCard(
                                            context,
                                            'Highest Demand',
                                            highestDemand['region'],
                                            '${highestDemand['percentage']}%',
                                            'of total requests',
                                            Colors.orange,
                                          ),
                                          SizedBox(height: 16),
                                          _buildDemandCard(
                                            context,
                                            'Growing Region',
                                            fastestGrowing['region'],
                                            '+${fastestGrowing['growth']}%',
                                            'increase in requests',
                                            Colors.green,
                                          ),
                                        ],
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
                
                // Usage Trends
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                            SizedBox(width: 12),
                            Text(
                              'Usage Trends',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Container(
                          height: 300,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('fertilizer_requests')
                                .orderBy('timestamp', descending: true)
                                .limit(30)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(child: Text('Error loading data'));
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              final requests = snapshot.data?.docs ?? [];
                              final data = _processUsageData(requests);

                              return Column(
                                children: [
                                  Expanded(
                                    child: LineChart(
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
                                                  return Padding(
                                                    padding: EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      data.labels[value.toInt()],
                                                      style: TextStyle(fontSize: 10),
                                                    ),
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
                                            dotData: FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Average Request: ',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '35kg',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          ' of General Compost',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Compost demand and usage trends',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<String>(
          value: _selectedPeriod,
          items: [
            DropdownMenuItem(value: 'week', child: Text('This Week')),
            DropdownMenuItem(value: 'month', child: Text('This Month')),
            DropdownMenuItem(value: 'quarter', child: Text('This Quarter')),
            DropdownMenuItem(value: 'year', child: Text('This Year')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
        ),
        SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Exporting analytics...')),
            );
          },
          icon: Icon(Icons.download),
          label: Text('Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        if (AppConfig.isDevelopment) ...[
          SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final seeder = FertilizerRequestSeeder();
                await seeder.seedData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Test data seeded successfully')),
                );
                setState(() {}); // Refresh the screen
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
            label: Text('Seed Test Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDemandCard(
    BuildContext context,
    String title,
    String location,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
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
          SizedBox(height: 12),
          Text(
            location,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(width: 4),
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

  ChartData _processUsageData(List<QueryDocumentSnapshot> requests) {
    Map<String, double> dailyData = {};

    for (var doc in requests.reversed) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateStr = DateFormat('dd/MM').format(date);
      final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;

      dailyData[dateStr] = (dailyData[dateStr] ?? 0) + quantity;
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
}

class ChartData {
  final List<FlSpot> spots;
  final List<String> labels;

  ChartData({required this.spots, required this.labels});
} 