import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For PointerDeviceKind

class AppColors {
  // Base Palette (Slate / Modern Blue-Grey)
  static const Color foreground = Color(0xFF0F172A); // Added back
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Colors.white;

  static const Color primary = Color(0xFF003D79); // Mandiri Blue Dark
  static const Color primaryForeground = Colors.white;

  // Mandiri Palette
  static const Color mandiriBlueDark = Color(0xFF003D79);
  static const Color mandiriBlueLight = Color(0xFF00A3E8);

  static const Color secondary = Color(0xFFE2E8F0); // Slate-200
  static const Color secondaryForeground = Color(0xFF1E293B); // Slate-800

  static const Color accent = Color(0xFF3B82F6); // Blue-500
  static const Color accentForeground = Colors.white;

  static const Color muted = Color(0xFFF1F5F9); // Slate-100
  static const Color mutedForeground = Color(0xFF64748B); // Slate-500

  static const Color destructive = Color(0xFFEF4444); // Red-500
  static const Color destructiveForeground = Colors.white; // Added missing
  static const Color success = Color(0xFF22C55E); // Green-500

  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color input = Color(0xFFE2E8F0);
  static const Color ring = Color(0xFF0F172A);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors
            .primary, // Using primary as secondary for now to keep it monochrome-ish
        surface: AppColors.surface,
        onSurface: AppColors.primary,
        error: AppColors.destructive,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card
      // Card
      // cardTheme: CardTheme(
      //   color: AppColors.surface,
      //   elevation: 0,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //     side: const BorderSide(color: AppColors.border),
      //   ),
      //   margin: const EdgeInsets.symmetric(vertical: 8),
      // ),

      // Input (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ), // Add floating label style etc
        hintStyle: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
