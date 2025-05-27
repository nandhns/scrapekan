import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';

class ServiceProvider extends StatelessWidget {
  final Widget child;

  const ServiceProvider({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthService>(
      future: AuthService.create(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Text('Error initializing services: ${snapshot.error}'),
              ),
            ),
          );
        }

        final authService = snapshot.data!;
        final connectivityService = ConnectivityService();

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(
              value: authService,
            ),
            ChangeNotifierProvider<ConnectivityService>.value(
              value: connectivityService,
            ),
          ],
          child: child,
        );
      },
    );
  }

  static ServiceProvider of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<ServiceProvider>()!;
  }
} 