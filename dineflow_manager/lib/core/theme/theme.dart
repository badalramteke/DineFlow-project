import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1F23);
  static const Color accentGreen = Color(0xFF00C853);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;

  // Added constants
  static const double radius = 16.0;
  static const double outerPadding = 20.0;
  static const LinearGradient bgGradient = LinearGradient(
    colors: [backgroundColor, Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.dark,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentGreen,
      cardColor: cardColor,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textGrey, displayColor: textWhite),
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        surface: cardColor,
        background: backgroundColor,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      primaryColor: accentGreen,
      cardColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: Colors.black87, displayColor: Colors.black),
      colorScheme: const ColorScheme.light(
        primary: accentGreen,
        surface: Colors.white,
        background: Color(0xFFF5F5F5),
      ),
      useMaterial3: true,
    );
  }
}
