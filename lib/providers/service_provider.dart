import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/waste_service.dart';
import '../services/compost_service.dart';
import '../services/notification_service.dart';

class ServiceProvider extends InheritedWidget {
  final FirebaseService firebaseService;
  final WasteService wasteService;
  final CompostService compostService;
  final NotificationService notificationService;

  ServiceProvider({
    Key? key,
    required Widget child,
  })  : firebaseService = FirebaseService(),
        wasteService = WasteService(),
        compostService = CompostService(),
        notificationService = NotificationService(),
        super(key: key, child: child);

  static ServiceProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ServiceProvider>();
    assert(provider != null, 'No ServiceProvider found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(ServiceProvider oldWidget) => false;
} 