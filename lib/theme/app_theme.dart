import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFEFBF04); // Yellow color
  static const Color buttonColor = Color(0xFF383838); // Black color for buttons
  static const Color bottomNavColor = Color(0xFF383838); // Dark gray color
  
  static ThemeData get theme {
    final baseTheme = ThemeData(
      primaryColor: primaryColor,
      primarySwatch: MaterialColor(primaryColor.value, {
        50: primaryColor.withOpacity(0.1),
        100: primaryColor.withOpacity(0.2),
        200: primaryColor.withOpacity(0.3),
        300: primaryColor.withOpacity(0.4),
        400: primaryColor.withOpacity(0.5),
        500: primaryColor.withOpacity(0.6),
        600: primaryColor.withOpacity(0.7),
        700: primaryColor.withOpacity(0.8),
        800: primaryColor.withOpacity(0.9),
        900: primaryColor,
      }),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: buttonColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(baseTheme.textTheme),
    );
  }
} 