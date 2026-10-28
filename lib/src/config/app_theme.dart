import 'package:flutter/material.dart';

class AppTheme {
  static const Color violeta = Color(0xFF8A2BE2);
  static const Color fondo = Color(0xFF101010);

  static ThemeData get oscuro => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: violeta,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: fondo,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1A1A),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );
}
