import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _cachedUserData;
  late final SharedPreferences _prefs;
  
  static const String _userDataKey = 'user_data_cache';

  AuthService._();

  static Future<AuthService> create() async {
    final service = AuthService._();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user data from Firestore with offline support
  Future<UserModel?> getUserData(String uid) async {
    // Return cached memory data if available
    if (_cachedUserData?.id == uid) {
      return _cachedUserData;
    }

    try {
      // Try to get data from Firestore
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        // If document doesn't exist, this is an error condition
        // We should never have an authenticated user without a document
        throw 'User profile not found. Please try logging in again.';
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure the ID is included in the data
      _cachedUserData = UserModel.fromFirestore(data);
      await _cacheUserData(_cachedUserData!);
      return _cachedUserData;
    } catch (e) {
      print('Get user data error: $e');
      
      // If offline, try to get cached data
      if (e.toString().contains('offline')) {
        final cachedData = await _loadCachedUserData(uid);
        if (cachedData != null) {
          _cachedUserData = cachedData;
          return cachedData;
        }
        throw 'Network error: Please check your internet connection';
      }
      throw 'Failed to load user data: $e';
    }
  }

  // Load cached user data from local storage
  Future<UserModel?> _loadCachedUserData(String uid) async {
    try {
      final jsonStr = _prefs.getString('${_userDataKey}_$uid');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr);
        return UserModel.fromJson(json as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error loading cached user data: $e');
    }
    return null;
  }

  // Save user data to local storage
  Future<void> _cacheUserData(UserModel userData) async {
    try {
      final jsonStr = jsonEncode(userData.toJson());
      await _prefs.setString('${_userDataKey}_${userData.id}', jsonStr);
    } catch (e) {
      print('Error caching user data: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user == null) {
        throw 'Sign in failed: No user returned';
      }
      
      // Try to get user data from Firestore
      try {
        final userData = await getUserData(result.user!.uid);
        if (userData != null) {
          return userData;
        }
      } catch (e) {
        // If offline, try to get cached data
        final cachedData = await _loadCachedUserData(result.user!.uid);
        if (cachedData != null) {
          return cachedData;
        }
        
        if (e.toString().contains('offline')) {
          throw 'Network error: Please check your internet connection. Some features may be limited in offline mode.';
        }
      }

      // If we get here, something is wrong - the user exists but has no data
      throw 'User data not found. Please contact support.';
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.code} - ${e.message}');
      if (e.code == 'network-request-failed') {
        throw 'Network error: Please check your internet connection';
      }
      throw e.message ?? 'Sign in failed';
    } catch (e) {
      print('Sign in error: $e');
      throw 'Sign in failed: $e';
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      // First check if a user with this email already exists
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw 'An account with this email already exists';
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw 'Registration failed: No user created';
      }

      // Create user data with the specified role
      final userData = await _createUserData(result.user!.uid, email, name, role);
      
      // Verify the role was properly set
      final verifiedData = await getUserData(result.user!.uid);
      if (verifiedData?.role != role) {
        // If role doesn't match, delete the user and throw error
        await result.user!.delete();
        await _firestore.collection('users').doc(result.user!.uid).delete();
        throw 'Failed to set user role properly';
      }
      
      return verifiedData;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.code} - ${e.message}');
      if (e.code == 'network-request-failed') {
        throw 'Network error: Please check your internet connection';
      }
      throw e.message ?? 'Registration failed';
    } catch (e) {
      print('Registration error: $e');
      throw 'Registration failed: $e';
    }
  }

  // Create user data in Firestore
  Future<UserModel> _createUserData(String uid, String email, String name, String role) async {
    final userData = UserModel(
      id: uid,
      email: email,
      name: name,
      role: role,
      points: 0,
      totalWaste: 0.0,
      co2Saved: 0.0,
      completedTasks: [],
      achievements: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final userDoc = _firestore.collection('users').doc(uid);
        final snapshot = await transaction.get(userDoc);
        
        if (!snapshot.exists) {
          // Remove the ID from Firestore document since it's the document ID
          final firestoreData = userData.toFirestore();
          firestoreData.remove('id');
          transaction.set(userDoc, firestoreData);
        } else {
          throw 'User document already exists';
        }
      });
      
      _cachedUserData = userData;
      await _cacheUserData(userData);
      return userData;
    } catch (e) {
      print('Create user data error: $e');
      throw 'Failed to create user data: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _prefs.remove('${_userDataKey}_$uid');
      }
      _cachedUserData = null;
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw 'Failed to sign out: $e';
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    _cachedUserData = null;
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _prefs.remove('${_userDataKey}_$uid');
    }
  }
} 