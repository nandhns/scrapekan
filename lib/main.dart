import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/service_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: 'AIzaSyA7tIhvBx5dKcz6NGHXExM7hLNmgs7EOf0',
          appId: '1:944281165543:web:1bb2b4a37b1c447ffc4c42',
          messagingSenderId: '944281165543',
          projectId: 'scrapekan',
          authDomain: 'scrapekan.firebaseapp.com',
          storageBucket: 'scrapekan.appspot.com',
        ),
      );
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Initialize Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Initialize services
    final authService = await AuthService.create();
    final connectivityService = ConnectivityService();

    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivityService),
      ],
      child: MyApp(),
    ));
  } catch (e) {
    print('Error initializing Firebase: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScraPekan',
      theme: ThemeData(
        primaryColor: Color(0xFFEFBF04),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFEFBF04),
          foregroundColor: Colors.white,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData) {
            return MainScreen();
          }
          
          return LoginScreen();
        },
      ),
    );
  }
}

/**
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ScraPekan")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogWasteScreen()),
            );
          },
          child: const Text("Log My Waste"),
        ),
      ),
    );
  }
} 
*/

