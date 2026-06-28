import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/phone_auth_screen.dart';
import '../screens/verification_screen.dart';
import '../screens/home_screen.dart';
import '../screens/shop_setup_screen.dart';
import '../screens/menu_management_screen.dart';
import '../screens/order_management_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/profile_screen.dart';
import 'app_routes.dart';

class SellerNavigator {
  SellerNavigator._();

  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _route(const SplashScreen());
      case AppRoutes.phoneAuth:
        return _route(const PhoneAuthScreen());
      case AppRoutes.verification:
        final args = settings.arguments as Map<String, String>;
        return _route(VerificationScreen(
          phoneNumber: args['phone']!,
          expectedOtp: args['otp']!,
        ));
      case AppRoutes.home:
        return _route(const SellerHomeScreen());
      case AppRoutes.shopSetup:
        return _route(const ShopSetupScreen());
      case AppRoutes.menuManagement:
        return _route(const MenuManagementScreen());
      case AppRoutes.orderManagement:
        return _route(const OrderManagementScreen());
      case AppRoutes.orderDetail:
        final orderId = settings.arguments as String;
        return _route(OrderDetailScreen(orderId: orderId));
      case AppRoutes.profile:
        return _route(const SellerProfileScreen());
      default:
        return _route(const SplashScreen());
    }
  }

  static MaterialPageRoute _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page, settings: RouteSettings(name: page.runtimeType.toString()));
  }

  static void splash(BuildContext context) {
    _pushReplace(context, const SplashScreen());
  }

  static void phoneAuth(BuildContext context) {
    _pushReplace(context, const PhoneAuthScreen());
  }

  static void verification(BuildContext context, {required String phone, required String otp}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VerificationScreen(phoneNumber: phone, expectedOtp: otp)),
    );
  }

  static void home(BuildContext context, {bool clearStack = true}) {
    final route = MaterialPageRoute(builder: (_) => const SellerHomeScreen());
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  static void shopSetup(BuildContext context, {bool clearStack = false}) {
    final route = MaterialPageRoute(builder: (_) => const ShopSetupScreen());
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
    } else {
      Navigator.of(context).push(route);
    }
  }

  static void menuManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MenuManagementScreen()),
    );
  }

  static void orderManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrderManagementScreen()),
    );
  }

  static Future<bool?> orderDetail(BuildContext context, {required String orderId}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: orderId),
        settings: const RouteSettings(name: AppRoutes.orderDetail),
      ),
    );
  }

  static Future<void> profile(BuildContext context) {
    return Navigator.of(context).push(
      _route(const SellerProfileScreen()),
    );
  }

  static void _pushReplace(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }
}
