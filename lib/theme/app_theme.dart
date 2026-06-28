import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFFF3EE);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color grey = Color(0xFF888888);
  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color dark = Color(0xFF1C1C1C);
  static const Color star = Color(0xFFFFC107);
  static const Color green = Color(0xFF4CAF50);
}

class AppTheme {
  static const Color orange = AppColors.orange;
  static const Color white = AppColors.white;
  static const Color darkBg = AppColors.darkBg;
  static const Color greyText = AppColors.grey;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
        ),
        scaffoldBackgroundColor: AppColors.lightBg,
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: AppColors.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      );
}
