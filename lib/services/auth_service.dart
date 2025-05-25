import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _userData;
  late SharedPreferences _prefs;
  bool _initialized = false;

  AuthService._();

  static Future<AuthService> create() async {
    final service = AuthService._();
    await service._init();
    return service;
  }

  Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    
    // Initialize user data if user is already logged in
    final user = _auth.currentUser;
    if (user != null) {
      await initUserData();
    }
  }

  User? get currentUser => _auth.currentUser;
  UserModel? get userData => _userData;
  bool get isLoggedIn => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> initUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      _userData = null;
      notifyListeners();
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _userData = UserModel.fromMap(doc.data()!, doc.id);
      }
      notifyListeners();
    } catch (e) {
      print('Error initializing user data: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await initUserData();
      return credential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      final now = DateTime.now();
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'createdAt': now,
        'updatedAt': now,
        'isActive': true,
        'points': 0,
        'totalWaste': 0,
        'totalCompost': 0,
      });

      await initUserData();
      return credential;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userData = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (address != null) updates['address'] = address;

      await _firestore.collection('users').doc(user.uid).update(updates);
      await initUserData();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Get auth state changes with user data
  Stream<UserModel?> get userDataChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _userData = null;
        return null;
      }
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) return null;
        return UserModel.fromMap(doc.data()!, doc.id);
      } catch (e) {
        print('Error in userDataChanges: $e');
        return null;
      }
    });
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      await _firestore.collection('users').doc(user.uid).update(data);
      await initUserData();
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  // Listen to user data changes
  Stream<UserModel?> userDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }
} 