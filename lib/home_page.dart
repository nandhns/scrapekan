import 'package:flutter/material.dart';
import 'pages/home_map_page.dart';
import 'pages/user_dashboard_page.dart';
import 'pages/fertilizer_request_page.dart';
import 'pages/analytics_heatmap_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeMapPage(),
    const UserDashboardPage(),
    const FertilizerRequestPage(),
    const AnalyticsHeatmapPage(),
  ];

  final List<String> _titles = [
    'Map',
    'Dashboard',
    'Request',
    'Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ScraPekan - ${_titles[_currentIndex]}"),
        backgroundColor: const Color(0xFFEFBF04),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFEFBF04),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
