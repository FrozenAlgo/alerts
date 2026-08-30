import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OnAlert design system — light card UI matching the product mockups.
class AppTheme {
  // Brand palette (from reference screens)
  static const Color kNavy = Color(0xFF0A1931);
  static const Color kCyan = Color(0xFF3ABEF9);
  static const Color kCyanDeep = Color(0xFF00AEEF);
  static const Color kAlertRed = Color(0xFFFF4B3E);
  static const Color kEmergencyRed = Color(0xFFB91C1C);
  static const Color kSuccess = Color(0xFF22C55E);
  static const Color kSuccessSoft = Color(0xFFDCFCE7);
  static const Color kWarning = Color(0xFFF59E0B);
  static const Color kPurple = Color(0xFF6366F1);

  // Surfaces
  static const Color kBackground = Color(0xFFF8F9FB);
  static const Color kSurface = Color(0xFFFFFFFF);
  static const Color kSurfaceMuted = Color(0xFFF1F5F9);
  static const Color kSurfaceTint = Color(0xFFE8F7FE);
  static const Color kBorder = Color(0xFFE8ECF1);

  // Text
  static const Color kTextPrimary = Color(0xFF0A1931);
  static const Color kTextSecondary = Color(0xFF8B95A5);
  static const Color kTextOnBrand = Color(0xFFFFFFFF);

  // Legacy aliases
  static const Color kPrimaryCyan = kCyan;
  static const Color kDarkSlate = kBackground;
  static const Color kGlassBase = kSurface;

  static const LinearGradient kBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kNavy, Color(0xFF122B4A)],
  );

  static const LinearGradient kCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kCyan, kCyanDeep],
  );

  static const LinearGradient kAlertGradient = LinearGradient(
    colors: [kAlertRed, Color(0xFFDC2626)],
  );

  static const LinearGradient kHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kNavy, Color(0xFF122B4A)],
  );

  static final BoxDecoration kCardDecoration = BoxDecoration(
    color: kSurface,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: kNavy.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static final BoxDecoration kGlassDecoration = kCardDecoration;

  static final BoxDecoration kElevatedCardDecoration = BoxDecoration(
    color: kSurface,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: kNavy.withValues(alpha: 0.08),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
      hintStyle: const TextStyle(color: kTextSecondary),
      prefixIcon: Icon(icon, color: kCyan, size: 22),
      filled: true,
      fillColor: kSurfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kCyan, width: 1.5),
      ),
    );
  }

  static ThemeData themeData() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: kBackground,
      colorScheme: const ColorScheme.light(
        primary: kCyan,
        onPrimary: kTextOnBrand,
        secondary: kNavy,
        onSecondary: kTextOnBrand,
        surface: kSurface,
        onSurface: kTextPrimary,
        error: kAlertRed,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: kTextPrimary,
      displayColor: kTextPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: kBackground,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: kTextPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: kTextPrimary,
        ),
        iconTheme: const IconThemeData(color: kNavy),
      ),
      cardTheme: CardThemeData(
        color: kSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceMuted,
        labelStyle: GoogleFonts.inter(color: kTextSecondary),
        hintStyle: GoogleFonts.inter(color: kTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kCyan, width: 1.5),
        ),
        prefixIconColor: kCyan,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kCyan,
          foregroundColor: kTextOnBrand,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kNavy,
          side: const BorderSide(color: kBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: kCyanDeep),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: kTextPrimary,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: kCyan),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kCyan;
          return kTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kCyan.withValues(alpha: 0.35);
          return kBorder;
        }),
      ),
    );
  }
}

const Color kPrimaryCyan = AppTheme.kCyan;
const Color kDarkSlate = AppTheme.kBackground;
const Color kGlassBase = AppTheme.kSurface;
