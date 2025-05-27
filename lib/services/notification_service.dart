import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firestore_schema.dart';
import 'firebase_service.dart';

class NotificationService extends FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'additionalData': additionalData,
      });
    } catch (e) {
      print('Error creating notification: $e');
      throw e;
    }
  }

  // Get notifications for current user
  Stream<QuerySnapshot> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      throw e;
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw e;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      throw e;
    }
  }

  // Get unread notifications count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get user's notifications
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
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
} 