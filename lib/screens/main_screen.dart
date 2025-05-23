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
import 'auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;
  UserModel? _userData;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in';
      });
      return;
    }

    try {
      final userData = await authService.getUserData(user.uid);
      if (userData == null) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading user data';
        });
        return;
      }

      setState(() {
        _userData = userData;
        _screens = _getScreensForRole(userData.role);
        _navigationItems = _getNavigationItemsForRole(userData.role);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              SizedBox(height: 16),
              if (_error == 'Please log in')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('Go to Login'),
                )
              else
                ElevatedButton(
                  onPressed: _loadUserData,
                  child: Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ScrapeKan'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                if (!context.mounted) return;
                
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to sign out: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navigationItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'Tips'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Rewards'),
        ];
      case 'farmer':
        return [
          BottomNavigationBarItem(icon: Icon(Icons.request_page), label: 'Request'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ];
      case 'admin':
        return [
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Confirm'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        ];
      case 'municipal':
        return [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Machines'),
        ];
      default:
        return [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ];
    }
  }
} 