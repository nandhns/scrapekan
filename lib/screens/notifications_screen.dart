import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../providers/service_provider.dart';
import '../models/firestore_schema.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = ServiceProvider.of(context).notificationService;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: () {
              _notificationService.markAllAsRead(_notificationService.currentUserId!);
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(_notificationService.currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _notificationService.deleteNotification(notification.id);
                },
                child: ListTile(
                  leading: _getNotificationIcon(notification.type),
                  title: Text(notification.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.message),
                      SizedBox(height: 4),
                      Text(
                        _getTimeAgo(notification.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _notificationService.markAsRead(notification.id);
                    _handleNotificationTap(notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'waste_dropoff':
        return CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.delete_outline, color: Colors.green),
        );
      case 'compost_started':
        return CircleAvatar(
          backgroundColor: Colors.brown[100],
          child: Icon(Icons.eco, color: Colors.brown),
        );
      case 'compost_completed':
        return CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.check_circle_outline, color: Colors.blue),
        );
      case 'reward_earned':
        return CircleAvatar(
          backgroundColor: Colors.amber[100],
          child: Icon(Icons.star_border, color: Colors.amber),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey[100],
          child: Icon(Icons.notifications_none, color: Colors.grey),
        );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'waste_dropoff':
        // Navigate to waste log details
        if (notification.data?.containsKey('wasteLogId') == true) {
          // Navigate to waste log details screen
        }
        break;
      case 'compost_started':
      case 'compost_completed':
        // Navigate to compost batch details
        if (notification.data?.containsKey('batchId') == true) {
          // Navigate to compost batch details screen
        }
        break;
      case 'reward_earned':
        // Navigate to rewards screen
        if (notification.data?.containsKey('rewardId') == true) {
          // Navigate to rewards screen
        }
        break;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 