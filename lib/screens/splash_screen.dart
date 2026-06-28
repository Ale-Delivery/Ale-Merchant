import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../navigation/seller_navigator.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

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
      backgroundColor: AppColors.darkCard,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.store_rounded, color: AppColors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Alee Seller',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your business',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.6), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
