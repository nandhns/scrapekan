import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _NotificationItem(
            title: 'New Achievement Unlocked!',
            message: 'You\'ve earned the "Green Warrior" badge.',
            time: '2 hours ago',
            isRead: false,
          ),
          _NotificationItem(
            title: 'Points Update',
            message: 'You\'ve earned 50 points for recycling.',
            time: '1 day ago',
            isRead: true,
          ),
          _NotificationItem(
            title: 'Weekly Summary',
            message: 'Check out your recycling impact this week.',
            time: '2 days ago',
            isRead: true,
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isRead;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey[300] : Theme.of(context).primaryColor,
          child: Icon(
            Icons.notifications,
            color: isRead ? Colors.grey[600] : Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(message),
            SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
} 