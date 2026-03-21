import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFA78BFA);
  static const Color accent = Color(0xFF10B981);

  // Generic colors mappings via context
  static Color background(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color cardBg(BuildContext context) => Theme.of(context).cardColor;
  static Color textBody(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
  static Color textHeading(BuildContext context) => Theme.of(context).textTheme.displayLarge?.color ?? Colors.black;
  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Light blue-grey background
      cardColor: Colors.white,
      dividerColor: Colors.black12,
      iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF475569)),
          bodyMedium: TextStyle(color: Color(0xFF475569)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      dividerColor: Colors.white24,
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF94A3B8)),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

