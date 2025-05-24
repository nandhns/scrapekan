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
      
      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (!doc.exists) {
        throw 'User profile not found';
      }

      try {
        // Convert Firestore data to UserModel
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id; // Add document ID to the data
        
        // Ensure lists are properly initialized
        data['completedTasks'] = (data['completedTasks'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        data['achievements'] = (data['achievements'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        
        // Ensure numeric fields are properly typed
        data['points'] = (data['points'] as num?)?.toInt() ?? 0;
        data['totalWaste'] = (data['totalWaste'] as num?)?.toDouble() ?? 0.0;
        data['co2Saved'] = (data['co2Saved'] as num?)?.toDouble() ?? 0.0;
        
        final userData = UserModel.fromFirestore(data);
        _cachedUserData = userData;
        await _cacheUserData(userData);
        
        return userData;
      } catch (e) {
        print('Error converting user data: $e');
        throw 'Error loading user profile. Please try again.';
      }
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

      // Create user data
      final userData = UserModel(
        id: result.user!.uid,
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
        // Save to Firestore
        final userDoc = _firestore.collection('users').doc(result.user!.uid);
        final firestoreData = userData.toFirestore();
        firestoreData.remove('id'); // Remove ID as it's the document ID
        await userDoc.set(firestoreData);

        // Cache the user data
        _cachedUserData = userData;
        await _cacheUserData(userData);

        return userData;
      } catch (e) {
        // If saving to Firestore fails, delete the auth user
        await result.user?.delete();
        print('Error saving user data: $e');
        throw 'Failed to create user profile';
      }
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