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
import '../widgets/custom_app_bar.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  UserModel? _userData;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navigationItems;
  String _currentTitle = 'ScraPekan';

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

  void _updateTitle(int index) {
    final titles = _getTitlesForRole(_userData?.role ?? 'citizen');
    setState(() {
      _currentTitle = titles[index];
    });
  }

  List<String> _getTitlesForRole(String role) {
    switch (role) {
      case 'citizen':
      case 'vendor':
        return ['Map', 'Log Waste', 'Dashboard', 'Tips', 'Rewards'];
      case 'farmer':
        return ['Fertilizer Request', 'Stock', 'Dashboard'];
      case 'admin':
        return ['Delivery Confirmation', 'Logs', 'Dashboard'];
      case 'municipal':
        return ['Overview', 'Analytics', 'Machines'];
      default:
        return ['Map'];
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
      appBar: CustomAppBar(title: _currentTitle),
      drawer: _buildDrawer(),
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _updateTitle(index);
          });
        },
        items: _navigationItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ScraPekan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Making recycling easier',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.recycling),
            title: Text('Recycle'),
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.leaderboard),
            title: Text('Leaderboard'),
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              // TODO: Navigate to About screen
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {
              // TODO: Navigate to Help screen
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              try {
                final authService = await AuthService.create();
                await authService.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: $e')),
                );
              }
            },
          ),
        ],
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