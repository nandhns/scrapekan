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
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/service_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/compost_batch_screen.dart';

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
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      ).catchError((e) {
        print('Error enabling Firestore persistence: $e');
        // Persistence might already be enabled
        return;
      });
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
    
    runApp(ServiceProvider(
      child: MyApp(
        authService: authService,
        connectivityService: connectivityService,
      ),
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
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasData) {
              return MainScreen();
            }
            
            return LoginScreen();
          },
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    NotificationsScreen(),
    CompostBatchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Compost',
          ),
        ],
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

