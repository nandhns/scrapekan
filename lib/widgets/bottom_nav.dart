// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';
import '../pages/citizen/home_map.dart';
import '../pages/citizen/log_waste.dart';
import '../pages/citizen/dashboard.dart';
import '../pages/farmer/fertilizer_request.dart';
import '../pages/farmer/fertilizer_stock.dart';
import '../pages/admin/delivery_confirm.dart';
import '../pages/admin/request_summary.dart';
import '../pages/municipal/admin_dashboard.dart';
import '../pages/municipal/analytics_heatmap.dart';
import '../pages/municipal/machine_monitoring.dart';

class BottomNav extends StatefulWidget {
  final int role; // 1=citizen, 2=farmer, 3=admin, 4=officer
  const BottomNav({super.key, required this.role});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [];
    List<BottomNavigationBarItem> navItems = [];

    switch (widget.role) {
      case 1:
        pages = [HomeMap(), LogWaste(), Dashboard()];
        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Stats'),
        ];
        break;
      case 2:
        pages = [FertilizerRequest(), FertilizerStock()];
        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.request_page), label: 'Request'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stock'),
        ];
        break;
      case 3:
        pages = [DeliveryConfirm(), RequestSummary()];
        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Confirm'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Requests'),
        ];
        break;
      case 4:
        pages = [AdminDashboard(), AnalyticsHeatmap(), MachineMonitoring()];
        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Heatmap'),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'IoT'),
        ];
        break;
    }

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
