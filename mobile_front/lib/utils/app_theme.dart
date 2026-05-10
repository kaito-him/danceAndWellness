import 'package:flutter/material.dart';

/// Gold and White Theme Configuration
class AppTheme {
  // Primary Gold Colors
  static const Color primaryGold  = Color(0xFFB89C4D); // brand gold
  static const Color lightGold    = Color(0xFFCDB96A); // lighter tint
  static const Color darkGold     = Color(0xFF8A7535); // darker shade
  static const Color paleGold     = Color(0xFFF5EDD6); // very light warm tint

  // Background / Surface Colors
  static const Color pageBackground = Color(0xFFEFE6D5); // premium warm beige
  static const Color pureWhite      = Color(0xFFFFFFFF);
  static const Color cardWhite      = Color(0xFFFFFFFF);
  static const Color lightGray      = Color(0xFFF0EDE6);
  static const Color mediumGray     = Color(0xFFDDD9D0);

  // Semantic Colors
  static const Color successGold  = Color(0xFF7A9A4A); // muted green — readable on warm bg
  static const Color errorGold    = Color(0xFFB85C3A); // warm terracotta for errors
  static const Color warningGold  = Color(0xFFB89C4D); // same brand gold for warnings

  // Text Colors
  static const Color textPrimary   = Color(0xFF2C2A25);
  static const Color textSecondary = Color(0xFF7A7468);
  static const Color textOnGold    = Color(0xFFFFFFFF);
  static const Color textOnWhite   = Color(0xFF2C2A25);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary:      primaryGold,
        secondary:    lightGold,
        tertiary:     darkGold,
        surface:      pageBackground,
        error:        errorGold,
        onPrimary:    textOnGold,
        onSecondary:  textOnGold,
        onSurface:    textPrimary,
        onError:      pureWhite,
      ),

      // Scaffold — every page gets the warm off-white
      scaffoldBackgroundColor: pageBackground,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGold,
        foregroundColor: pureWhite,
        elevation: 2,
        centerTitle: true,
        iconTheme: IconThemeData(color: pureWhite),
        titleTextStyle: TextStyle(
          color: pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: primaryGold.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: paleGold, width: 1),
        ),
      ),

      // Input fields — fill matches page background so they feel embedded
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mediumGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mediumGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorGold),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorGold, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: pureWhite,
          elevation: 2,
          shadowColor: primaryGold.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGold,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: primaryGold,
        size: 24,
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGold,
        foregroundColor: pureWhite,
        elevation: 4,
      ),

      // Bottom Nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pureWhite,
        selectedItemColor: primaryGold,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: mediumGray,
        thickness: 1,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGold,
        linearTrackColor: paleGold,
        circularTrackColor: paleGold,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGold,
        contentTextStyle: const TextStyle(color: pureWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: pureWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: paleGold,
        selectedColor: primaryGold,
        labelStyle: const TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: pureWhite),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
