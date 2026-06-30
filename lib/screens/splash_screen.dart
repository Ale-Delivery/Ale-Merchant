import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_storage_service.dart';
import '../navigation/seller_navigator.dart';
import '../theme/theme_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1000) + const Duration(seconds: 2));
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final phone = await LocalStorageService.getUserPhone();
    final profileComplete = await LocalStorageService.isProfileComplete();

    if (phone != null && profileComplete) {
      SellerNavigator.home(context, clearStack: true);
    } else {
      SellerNavigator.phoneAuth(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'SELLER PORTAL',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textMuted,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
