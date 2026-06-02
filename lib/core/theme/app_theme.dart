import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors from Municipality of Pila Official Palette
  static const Color primaryOrange = Color(0xFFE04A17); // #E04A17 - Orange
  static const Color primaryYellow = Color(0xFFF2B705); // #F2B705 - Yellow
  static const Color lightYellow = Color(0xFFFFD166); // #FFD166 - Light Yellow
  static const Color peach = Color(0xFFFFB07C); // #FFB07C - Peach
  static const Color coral = Color(0xFFEF5B4C); // #EF5B4C - Coral
  static const Color lightPeach = Color(0xFFF7E7E1); // #F7E7E1 - Light Peach

  // Neutral Colors from Palette
  static const Color lightGray = Color(0xFFEFEFEF); // #EFEFEF - Light Gray
  static const Color darkGray = Color(0xFF333333); // #333333 - Dark Gray
  static const Color black = Color(0xFF111111); // #111111 - Black
  static const Color white = Color(0xFFFFFFFF); // #FFFFFF - White

  // Functional Colors (mapped to palette with yellow as primary)
  static const Color primaryBlue = primaryYellow; // Using yellow as primary
  static const Color primaryRed = coral;
  static const Color accentGold = primaryYellow;
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = primaryOrange;
  static const Color backgroundGrey = Color(0xFFFFFDF5); // Slight yellow tint
  static const Color cardWhite = white;
  static const Color textDark = darkGray;
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = lightGray;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryYellow,
      primary: primaryYellow,
      secondary: primaryOrange,
      surface: cardWhite,
      error: coral,
    ),
    scaffoldBackgroundColor: backgroundGrey,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundGrey,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: textDark),
    ),
    cardTheme: CardThemeData(
      color: cardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryYellow,
        foregroundColor: black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryYellow,
        side: const BorderSide(color: primaryYellow, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryYellow,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: coral, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryYellow,
      foregroundColor: black,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryYellow,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightYellow,
      selectedColor: primaryYellow,
      labelStyle: const TextStyle(color: textDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    fontFamily: 'Roboto',
  );

  static Color statusColor(String status) {
    switch (status) {
      case 'Submitted':
        return const Color(0xFFD97706); // Darker yellow/amber
      case 'Seen':
        return const Color(0xFFF59E0B); // Amber
      case 'Validated':
        return const Color(0xFFEA580C); // Dark orange
      case 'Queued':
        return primaryOrange;
      case 'In Progress':
        return coral;
      case 'Completed':
        return successGreen;
      case 'Rejected':
        return darkGray;
      default:
        return textMuted;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'Submitted':
        return Icons.upload_rounded;
      case 'Seen':
        return Icons.visibility_rounded;
      case 'Validated':
        return Icons.verified_rounded;
      case 'Queued':
        return Icons.queue_rounded;
      case 'In Progress':
        return Icons.construction_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}
