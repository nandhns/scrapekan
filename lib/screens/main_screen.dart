import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'home_map.dart';
import 'log_waste_screen.dart';
import 'dashboard_screen.dart';
import 'compost_tips_screen.dart';
import 'rewards_screen.dart';
import 'farmer/fertilizer_request_screen.dart';
import 'farmer/fertilizer_stock_screen.dart';
import 'admin/delivery_confirmation_screen.dart';
import 'admin/fertilizer_logs_screen.dart';
import 'municipal/admin_dashboard_screen.dart';
import 'municipal/analytics_screen.dart';
import 'municipal/machine_monitoring_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      // Handle not logged in state
      return Scaffold(
        body: Center(
          child: Text('Please log in'),
        ),
      );
    }

    return FutureBuilder<UserModel?>(
      future: authService.getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text('Error loading user data'),
            ),
          );
        }

        final userData = snapshot.data!;
        final screens = _getScreensForRole(userData.role);
        final navigationItems = _getNavigationItemsForRole(userData.role);

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: navigationItems,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  List<Widget> _getScreensForRole(String role) {
    switch (role) {
      case 'citizen':
      case 'vendor':
        return [
          HomeMap(),
          LogWasteScreen(),
          DashboardScreen(),
          CompostTipsScreen(),
          RewardsScreen(),
        ];
      case 'farmer':
        return [
          FertilizerRequestScreen(),
          FertilizerStockScreen(),
          DashboardScreen(),
        ];
      case 'admin':
        return [
          DeliveryConfirmationScreen(),
          FertilizerLogsScreen(),
          DashboardScreen(),
        ];
      case 'municipal':
        return [
          AdminDashboardScreen(),
          AnalyticsScreen(),
          MachineMonitoringScreen(),
        ];
      default:
        return [HomeMap()];
    }
  }

  List<BottomNavigationBarItem> _getNavigationItemsForRole(String role) {
    switch (role) {
      case 'citizen':
      case 'vendor':
        return [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Log Waste'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.tips_and_updates), label: 'Tips'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Rewards'),
        ];
      case 'farmer':
        return [
          BottomNavigationBarItem(icon: Icon(Icons.request_page), label: 'Request'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ];
      case 'admin':
        return [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Delivery'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ];
      case 'municipal':
        return [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor), label: 'Machines'),
        ];
      default:
        return [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ];
    }
  }
} 