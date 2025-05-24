import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get wasteLogsRef => _firestore.collection('waste_logs');
  CollectionReference get dropoffPointsRef => _firestore.collection('dropoff_points');
  CollectionReference get compostBatchesRef => _firestore.collection('compost_batches');
  CollectionReference get notificationsRef => _firestore.collection('notifications');
  CollectionReference get rewardsRef => _firestore.collection('rewards');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Get user role
  Future<String?> getCurrentUserRole() async {
    if (currentUserId == null) return null;
    final doc = await usersRef.doc(currentUserId).get();
    return doc.exists ? (doc.data() as Map<String, dynamic>)['role'] : null;
  }
} 