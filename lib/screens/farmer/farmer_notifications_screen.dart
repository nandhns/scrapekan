import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'fertilizer_request_screen.dart';

class FarmerNotificationsScreen extends StatelessWidget {
  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Stay updated on your fertilizer requests',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _dummyNotifications.length,
                  separatorBuilder: (context, index) => Divider(height: 32),
                  itemBuilder: (context, index) {
                    final notification = _dummyNotifications[index];
                    return _NotificationItem(
                      title: notification['title']!,
                      message: notification['message']!,
                      time: notification['time']!,
                      isRead: notification['isRead'] as bool,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: EdgeInsets.only(top: 4, right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRead ? Colors.grey[300] : Theme.of(context).primaryColor,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Dummy data for notifications
final List<Map<String, dynamic>> _dummyNotifications = [
  {
    'title': 'Fertilizer Request Approved',
    'message': 'Your request for 50kg of organic fertilizer has been approved.',
    'time': '2 hours ago',
    'isRead': false,
  },
  {
    'title': 'Delivery Scheduled',
    'message': 'Your fertilizer will be delivered on Monday, March 15th.',
    'time': '1 day ago',
    'isRead': true,
  },
  {
    'title': 'New Batch Available',
    'message': 'A new batch of premium compost is now available for request.',
    'time': '2 days ago',
    'isRead': true,
  },
]; 