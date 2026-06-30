import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const GlassAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: AppBar(
          title: Text(title),
          centerTitle: centerTitle,
          actions: actions,
          leading: leading,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
