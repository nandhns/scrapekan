import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationType {
  static const requestApproved = 'REQUEST_APPROVED';
  static const newStock = 'NEW_STOCK';
  static const deliveryScheduled = 'DELIVERY_SCHEDULED';
}

class _NotificationData {
  final IconData icon;
  final Color color;

  _NotificationData(this.icon, this.color);
}

class FarmerNotificationsScreen extends StatefulWidget {
  @override
  _FarmerNotificationsScreenState createState() => _FarmerNotificationsScreenState();
}

class _FarmerNotificationsScreenState extends State<FarmerNotificationsScreen> {
  late NotificationService _notificationService;

  final Map<String, _NotificationData> _notificationTypes = {
    NotificationType.requestApproved: _NotificationData(
      Icons.check_circle_outline,
      Colors.green,
    ),
    NotificationType.newStock: _NotificationData(
      Icons.inventory_2_outlined,
      Colors.blue,
    ),
    NotificationType.deliveryScheduled: _NotificationData(
      Icons.local_shipping_outlined,
      Colors.orange,
    ),
  };

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
  }

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
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Stay updated on your fertilizer requests',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _notificationService.markAllAsRead(),
                      child: Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: AppTheme.buttonColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (notifications.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => Divider(height: 32),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final data = notification.data() as Map<String, dynamic>;
                      
                      if (!data['isRead']) {
                        _notificationService.markAsRead(notification.id);
                      }

                      final type = data['type'] as String? ?? NotificationType.requestApproved;
                      final notificationData = _notificationTypes[type] ?? 
                          _NotificationData(Icons.notifications_outlined, Colors.grey);

                      return _NotificationItem(
                        title: data['title'] ?? '',
                        message: data['message'] ?? '',
                        time: _timeAgo(data['createdAt'].toDate()),
                        isRead: data['isRead'] ?? false,
                        icon: notificationData.icon,
                        iconColor: notificationData.color,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final IconData icon;
  final Color iconColor;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 