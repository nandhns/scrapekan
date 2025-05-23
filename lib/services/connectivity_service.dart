import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  bool _hasConnection = true;
  final Connectivity _connectivity = Connectivity();

  ConnectivityService() {
    _initConnectivity();
    _setupConnectivityListener();
  }

  bool get hasConnection => _hasConnection;

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Connectivity check failed: $e');
      _hasConnection = false;
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    bool wasConnected = _hasConnection;
    _hasConnection = result != ConnectivityResult.none;
    
    if (wasConnected != _hasConnection) {
      notifyListeners();
    }
  }
} 