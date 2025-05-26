import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  // Changed from _firestore to firestore_ to make it protected
  final FirebaseFirestore firestore_;
  final FirebaseAuth auth_;

  FirebaseService()
      : firestore_ = FirebaseFirestore.instance,
        auth_ = FirebaseAuth.instance;

  // Collection references with proper typing
  CollectionReference<Map<String, dynamic>> get usersRef => firestore_.collection('users');
  CollectionReference<Map<String, dynamic>> get wasteLogsRef => firestore_.collection('waste_logs');
  CollectionReference<Map<String, dynamic>> get dropoffPointsRef => firestore_.collection('dropoff_points');
  CollectionReference<Map<String, dynamic>> get compostBatchesRef => firestore_.collection('compost_batches');
  CollectionReference<Map<String, dynamic>> get notificationsRef => firestore_.collection('notifications');
  CollectionReference<Map<String, dynamic>> get rewardsRef => firestore_.collection('rewards');

  // Get current user ID
  String? get currentUserId => auth_.currentUser?.uid;

  // Check if user is logged in
  bool get isUserLoggedIn => auth_.currentUser != null;

  // Get user role
  Future<String?> getCurrentUserRole() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await usersRef.doc(currentUserId).get();
      if (!doc.exists) return null;
      
      final data = doc.data();
      return data?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
}