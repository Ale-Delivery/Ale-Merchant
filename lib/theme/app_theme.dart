import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens (Seller) ────────────────────────────────────
// Mirrors buyer app tokens for brand consistency.

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeDark = Color(0xFFE85A28);
  static const Color orangeLight = Color(0xFFFFF3EE);

  // ── Surfaces ─────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color lightBg = Color(0xFFF5F6FA);

  // ── Text ─────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1E1E2C);
  static const Color muted = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);

  // ── Borders & Dividers ───────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF0F1F5);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color star = Color(0xFFF59E0B);

  // ── Dark ─────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF1E1E2C);
  static const Color darkEnd = Color(0xFF2D2D44);

  // ── Backward compat aliases ──────────────────────────────────
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color dark = Color(0xFF1E1E2C);
}

// ─── Gradient Presets ──────────────────────────────────────────

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dark = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient avatar = LinearGradient(
    colors: [Color(0xFFFF8C61), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Theme ─────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static const Color orange = AppColors.orange;
  static const Color white = AppColors.white;
  static const Color darkBg = AppColors.darkBg;
  static const Color greyText = AppColors.muted;

  static ThemeData get theme {
    final baseText = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        onPrimary: AppColors.white,
        surface: AppColors.bg,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Poppins',
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.ink),
        bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.ink),
        bodySmall: baseText.bodySmall?.copyWith(color: AppColors.muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.orange, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.hint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.orange,
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
