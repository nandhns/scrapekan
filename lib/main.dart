import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_map.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Platform-specific initialization
    if (kIsWeb) {
      // Web-specific settings
      FirebaseFirestore.instance.enablePersistence();
    } else {
      // Android-specific settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
    
    // Initialize services after Firebase is ready
    final authService = await AuthService.create();
    final connectivityService = ConnectivityService();
    
    print('Firebase initialized successfully for ${kIsWeb ? 'Web' : 'Android'}');
    
    runApp(MyApp(
      authService: authService,
      connectivityService: connectivityService,
    ));
    
  } catch (e) {
    print('Error initializing Firebase: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Error initializing app',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final ConnectivityService connectivityService;

  const MyApp({
    Key? key,
    required this.authService,
    required this.connectivityService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(
          value: authService,
        ),
        ChangeNotifierProvider<ConnectivityService>.value(
          value: connectivityService,
        ),
      ],
      child: MaterialApp(
        title: 'ScrapeKan',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.notoSansTextTheme(
            Theme.of(context).textTheme,
          ).copyWith(
            // Ensure symbols are covered
            bodyMedium: TextStyle(
              fontFamilyFallback: [
                'Noto Sans Symbols',
                'Noto Sans Symbols 2',
              ],
            ),
            bodyLarge: TextStyle(
              fontFamilyFallback: [
                'Noto Sans Symbols',
                'Noto Sans Symbols 2',
              ],
            ),
            bodySmall: TextStyle(
              fontFamilyFallback: [
                'Noto Sans Symbols',
                'Noto Sans Symbols 2',
              ],
            ),
          ),
          fontFamily: GoogleFonts.notoSans().fontFamily,
        ),
        home: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    
    // Add a small delay to ensure smooth transition
    await Future.delayed(Duration(milliseconds: 500));
    
    if (!mounted) return;

    // Check connectivity first
    if (!connectivityService.hasConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are offline. Some features may be limited.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (authService.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your app logo here
            Icon(
              Icons.recycling,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'ScrapeKan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
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

