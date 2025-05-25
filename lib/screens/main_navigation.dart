import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/scrapekan_app_bar.dart';
// ... other imports

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userRole = authService.userData?.role ?? 'User';

    return Scaffold(
      appBar: ScraPekanAppBar(
        userRole: userRole,
        onNotificationTap: () {
          // Navigate to notifications
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationsScreen(),
            ),
          );
        },
        onProfileTap: () {
          // Navigate to profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(),
            ),
          );
        },
      ),
      body: _buildBody(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navigationItems,
        backgroundColor: AppTheme.bottomNavColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildBody(int index) {
    // Your existing body building logic
  }

  List<BottomNavigationBarItem> get _navigationItems {
    // Your existing navigation items
  }
}
// ... rest of the file 