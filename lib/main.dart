import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const ScraPekanApp());
}

class ScraPekanApp extends StatelessWidget {
  const ScraPekanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScraPekan',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEFBF04)),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF383838)),
        ),
      ),
      home: const HomePage(),
    );
  }
}
