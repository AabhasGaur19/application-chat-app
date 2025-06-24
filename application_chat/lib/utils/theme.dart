import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get material3Theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 16),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}