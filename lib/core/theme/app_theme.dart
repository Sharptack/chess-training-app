import 'package:flutter/material.dart';

class AppTheme {
  static ColorScheme _lightScheme = const ColorScheme.light(
    primary: Color(0xFF1565C0),
    secondary: Color(0xFF00ACC1),
    surface: Colors.white,
  );

  static ColorScheme _darkScheme = const ColorScheme.dark(
    primary: Color(0xFF90CAF9),
    secondary: Color(0xFF4DD0E1),
    surface: Color(0xFF121212),
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(centerTitle: true),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(centerTitle: true),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );
}