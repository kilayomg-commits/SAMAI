import 'package:flutter/material.dart';

class SamaiTheme {
  static const seed = Color(0xFF2E7D74); // verde azulado sereno
  static const sand = Color(0xFFF6F1E9);
  static const crisis = Color(0xFFB3261E);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, surface: sand);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: sand,
      appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: sand),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
