import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_schema.dart';
import 'firebase_service.dart';

class NotificationService extends FirebaseService {
  // Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return notificationsRef
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel(
                  id: doc.id,
                  recipientId: doc['recipientId'],
                  title: doc['title'],
                  message: doc['message'],
                  type: doc['type'],
                  read: doc['read'],
                  timestamp: (doc['timestamp'] as Timestamp).toDate(),
                  data: doc['data'],
                ))
            .toList());
  }

  // Get notifications by type
  Stream<List<NotificationModel>> getNotificationsByType(
    String userId,
    String type,
  ) {
    return notificationsRef
        .where('recipientId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel(
                  id: doc.id,
                  recipientId: doc['recipientId'],
                  title: doc['title'],
                  message: doc['message'],
                  type: doc['type'],
                  read: doc['read'],
                  timestamp: (doc['timestamp'] as Timestamp).toDate(),
                  data: doc['data'],
                ))
            .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await notificationsRef.doc(notificationId).update({
      'read': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    
    final notifications = await notificationsRef
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await notificationsRef.doc(notificationId).delete();
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return notificationsRef
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
} 