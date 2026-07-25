import 'package:flutter/material.dart';

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  Color get textPrimary =>
      isDark ? const Color(0xFFF0F0F5) : const Color(0xFF0F1014);
  Color get textSecondary =>
      isDark ? const Color(0xCCDDDEE3) : const Color(0xFF1E1E2C);
  Color get textMuted =>
      isDark ? const Color(0xFF8E8EA0) : const Color(0xFF6B7280);
  Color get textHint =>
      isDark ? const Color(0xFF5C5C6F) : const Color(0xFF9CA3AF);

  Color get cardBg => isDark ? const Color(0xFF181B22) : Colors.white;
  Color get cardBorder =>
      isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E7EB);

  Color get inputBg => isDark ? const Color(0xFF13151A) : Colors.white;

  Color get chipBg =>
      isDark ? const Color(0xFF1E2128) : const Color(0xFFF3F4F6);
  Color get chipActiveBg => const Color(0xFFFF416C);

  Color get divider =>
      isDark ? const Color(0xFF22252D) : const Color(0xFFE5E7EB);

  Color get shimmerBase =>
      isDark ? const Color(0xFF181B22) : const Color(0xFFF0F0F0);
  Color get shimmerHighlight =>
      isDark ? const Color(0xFF22252D) : const Color(0xFFE0E0E0);

  Color get appBarBg => isDark ? const Color(0xFF0F1117) : Colors.white;

  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFFF416C).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFBBF24);
      case 'accepted':
      case 'preparing':
        return const Color(0xFF60A5FA);
      case 'on_the_way':
      case 'out_for_delivery':
        return const Color(0xFFA78BFA);
      case 'delivered':
        return const Color(0xFF34D399);
      case 'cancelled':
        return const Color(0xFFF87171);
      default:
        return textMuted;
    }
  }
}
