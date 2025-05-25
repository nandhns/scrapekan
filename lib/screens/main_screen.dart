import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';
// Citizen screens
import 'citizen/home_map.dart';
import 'citizen/log_waste_screen.dart';
import 'citizen/dashboard_screen.dart';
import 'citizen/compost_tips_screen.dart';
import 'citizen/rewards_screen.dart';
// Farmer screens
import 'farmer/fertilizer_request_screen.dart';
import 'farmer/fertilizer_stock_screen.dart';
import 'farmer/farmer_notifications_screen.dart';
// Admin screens
import 'admin/delivery_confirmation_screen.dart';
import 'admin/fertilizer_logs_screen.dart';
import 'admin/farmer_requests_screen.dart';
// Municipal screens
import 'municipal/admin_dashboard_screen.dart';
import 'municipal/analytics_screen.dart';
import 'municipal/machine_monitoring_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;
  UserModel? _userData;
  List<Widget>? _screens;
  String _currentTitle = 'ScraPekan';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in';
      });
      // Navigate to login screen if no user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
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

      // Validate role
      if (!['citizen', 'vendor', 'farmer', 'admin', 'municipal'].contains(userData.role)) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid user role';
        });
        return;
      }

      setState(() {
        _userData = userData;
        _screens = _getScreensForRole(userData.role);
        _currentTitle = _getTitlesForRole(userData.role)[0];
        _selectedIndex = 0;
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

  List<String> _getTitlesForRole(String role) {
    switch (role) {
      case 'citizen':
      case 'vendor':
        return ['Drop-off Points', 'Log Waste', 'Dashboard', 'Tips', 'Rewards'];
      case 'farmer':
        return ['Fertilizer Request', 'Availability', 'Notifications'];
      case 'admin':
        return ['Delivery Confirmation', 'Logs', 'Requests'];
      case 'municipal':
        return ['Dashboard', 'Analytics', 'Machines'];
      default:
        return ['Drop-off Points'];
    }
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
          FarmerNotificationsScreen(),
        ];
      case 'admin':
        return [
          DeliveryConfirmationScreen(),
          FertilizerLogsScreen(),
          FarmerRequestsScreen(),
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
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Log Waste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Rewards',
          ),
        ];
      case 'farmer':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Availability',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ];
      case 'admin':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),
        ];
      case 'municipal':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.memory),
            label: 'Machines',
          ),
        ];
      default:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ];
    }
  }

  void _updateTitle(int index) {
    final titles = _getTitlesForRole(_userData?.role ?? 'citizen');
    setState(() {
      _currentTitle = titles[index];
    });
  }

  void _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await authService.signOut();
      
      if (!mounted) return;
      
      Navigator.pop(context);
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _userData == null || _screens == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'No user data available'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final navigationItems = _getNavigationItemsForRole(_userData!.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens!,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _updateTitle(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: navigationItems,
      ),
    );
  }

  Widget _buildDrawer() {
    final titles = _getTitlesForRole(_userData!.role);
    final navigationItems = _getNavigationItemsForRole(_userData!.role);

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
                  _userData!.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _userData!.email,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Role: ${_userData!.role.substring(0, 1).toUpperCase()}${_userData!.role.substring(1)}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(navigationItems.length, (index) => 
            ListTile(
              leading: navigationItems[index].icon,
              title: Text(titles[index]),
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }
} 