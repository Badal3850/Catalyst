import 'package:flutter/material.dart';

/// CoreBrain design system — light and dark [ThemeData] definitions.
class AppTheme {
  AppTheme._();

  // ── Brand palette ────────────────────────────────────────────────────────
  static const Color _primaryLight = Color(0xFF5B4FE9);
  static const Color _primaryDark = Color(0xFF8B82F6);
  static const Color _surfaceLight = Color(0xFFF5F5F7);
  static const Color _surfaceDark = Color(0xFF1C1C1E);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF2C2C2E);

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: Colors.white,
      surface: _surfaceLight,
      onSurface: Color(0xFF1C1C1E),
      surfaceContainerHighest: _cardLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surfaceLight,
      cardColor: _cardLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceLight,
        foregroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardLight,
        indicatorColor: _primaryLight.withAlpha(30),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _primaryLight.withAlpha(20),
        labelStyle: const TextStyle(
          color: _primaryLight,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: Color(0xFF1C1C1E),
      surface: _surfaceDark,
      onSurface: Color(0xFFF5F5F7),
      surfaceContainerHighest: _cardDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surfaceDark,
      cardColor: _cardDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceDark,
        foregroundColor: Color(0xFFF5F5F7),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF5F5F7),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardDark,
        indicatorColor: _primaryDark.withAlpha(40),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: Color(0xFF1C1C1E),
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _primaryDark.withAlpha(30),
        labelStyle: const TextStyle(
          color: _primaryDark,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
      ),
    );
  }
}
