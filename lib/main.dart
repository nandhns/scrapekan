import 'package:flutter/material.dart';
import 'screens/log_waste_screen.dart';

void main() {
  runApp(const ScraPekanApp());
}

class ScraPekanApp extends StatelessWidget {
  const ScraPekanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScraPekan',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFEFBF04)),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF383838)),
        ),
      ),
      home: const HomePage(), // temporary
    );
  }
}

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

