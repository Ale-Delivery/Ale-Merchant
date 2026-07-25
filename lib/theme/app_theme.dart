import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens ─────────────────────────────────────────────
// Single source of truth for ALL colors, fonts, radii, gradients.

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────
  static const Color orange = Color(0xFFFF416C); // Neon Pink/Orange
  static const Color orangeDark = Color(0xFFFF4B2B);
  static const Color orangeLight = Color(0xFFFFECEF);

  // ── Surfaces ─────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFF0F1014); // Deep Dark bg
  static const Color surface = Color(0xFF16181D); // Dark surface

  static const Color lightBg = Color(0xFFF8F9FA); // Light bg
  static const Color lightSurface = Color(0xFFFFFFFF); // Light surface

  // ── Text ─────────────────────────────────────────────────────
  static const Color ink = Color(0xFFF8F9FA); // White text
  static const Color muted = Color(0xFFA1A1AA); // Zinc-400
  static const Color hint = Color(0xFF71717A); // Zinc-500

  static const Color lightInk = Color(0xFF0F1014); // Dark text
  static const Color lightMuted = Color(0xFF71717A);
  static const Color lightHint = Color(0xFFA1A1AA);

  // ── Borders & Dividers ───────────────────────────────────────
  static const Color border = Color(0xFF272A30);
  static const Color divider = Color(0xFF272A30);

  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightDivider = Color(0xFFE4E4E7);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color green = Color(0xFF10B981); // Emerald
  static const Color red = Color(0xFFEF4444); // Red
  static const Color amber = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color star = Color(0xFFF59E0B);

  // ── Dark (profile header, splash) ────────────────────────────
  static const Color darkBg = Color(0xFF0F1014);
  static const Color darkCard = Color(0xFF16181D);
  static const Color darkEnd = Color(0xFF1C1E26);

  // ── Backward compat aliases ──────────────────────────────────
  static const Color grey = Color(0xFFA1A1AA); // same as muted
  static const Color greyLight = Color(0xFF272A30); // same as border
  static const Color dark = Color(0xFF0F1014); // same as ink
}

// ─── Gradient Presets ──────────────────────────────────────────

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dark = LinearGradient(
    colors: [Color(0xFF0F1014), Color(0xFF1C1E26)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient avatar = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFFF416C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statusReady = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Theme ─────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // Legacy aliases (keep existing code compiling)
  static const Color orange = AppColors.orange;
  static const Color white = AppColors.white;
  static const Color darkBg = AppColors.darkBg;
  static const Color greyText = AppColors.muted;

  static ThemeData get darkTheme {
    final baseDarkText =
        GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        onPrimary: AppColors.white,
        surface: AppColors.bg,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: baseDarkText.copyWith(
        headlineLarge: baseDarkText.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineMedium: baseDarkText.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: baseDarkText.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseDarkText.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseDarkText.bodyLarge?.copyWith(color: AppColors.ink),
        bodyMedium: baseDarkText.bodyMedium?.copyWith(color: AppColors.ink),
        bodySmall: baseDarkText.bodySmall?.copyWith(color: AppColors.muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // For Glassmorphism
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.hint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF181B22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: const BorderSide(color: Color(0xFF2A2D35), width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.orange,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.white,
        contentTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.bg,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseLightText =
        GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        onPrimary: AppColors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightInk,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: baseLightText.copyWith(
        headlineLarge: baseLightText.headlineLarge?.copyWith(
          color: AppColors.lightInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineMedium: baseLightText.headlineMedium?.copyWith(
          color: AppColors.lightInk,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: baseLightText.titleLarge?.copyWith(
          color: AppColors.lightInk,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseLightText.titleMedium?.copyWith(
          color: AppColors.lightInk,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseLightText.bodyLarge?.copyWith(color: AppColors.lightInk),
        bodyMedium:
            baseLightText.bodyMedium?.copyWith(color: AppColors.lightInk),
        bodySmall:
            baseLightText.bodySmall?.copyWith(color: AppColors.lightMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.lightInk,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightInk,
          letterSpacing: -0.5,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.orange,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightInk,
        contentTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.lightBg,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
