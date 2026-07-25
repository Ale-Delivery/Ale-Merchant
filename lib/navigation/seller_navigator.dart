import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/phone_auth_screen.dart';
import '../screens/verification_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home_screen.dart';
import '../screens/shop_setup_screen.dart';
import '../screens/menu_management_screen.dart';
import '../screens/order_management_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/earnings_screen.dart';
import '../screens/operations_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/promotions_screen.dart';
import '../screens/staff_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/reviews_screen.dart';
import '../screens/notification_prefs_screen.dart';
import '../screens/kitchen_display_screen.dart';
import '../screens/support_screen.dart';
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
        return _route(const MainShell());
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
      case AppRoutes.analytics:
        return _route(const AnalyticsScreen());
      case AppRoutes.earnings:
        return _route(const EarningsScreen());
      case AppRoutes.operations:
        return _route(const OperationsScreen());
      case AppRoutes.inventory:
        return _route(const InventoryScreen());
      case AppRoutes.promotions:
        return _route(const PromotionsScreen());
      case AppRoutes.staff:
        return _route(const StaffScreen());
      case AppRoutes.reports:
        return _route(const ReportsScreen());
      case AppRoutes.reviews:
        return _route(const ReviewsScreen());
      case AppRoutes.notificationPrefs:
        return _route(const NotificationPrefsScreen());
      case AppRoutes.kitchenDisplay:
        return _route(const KitchenDisplayScreen());
      case AppRoutes.support:
        return _route(const SupportScreen());
      default:
        return _route(const SplashScreen());
    }
  }

  static MaterialPageRoute _route(Widget page) {
    return MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: page.runtimeType.toString()));
  }

  static void splash(BuildContext context) {
    _pushReplace(context, const SplashScreen());
  }

  static void phoneAuth(BuildContext context) {
    _pushReplace(context, const PhoneAuthScreen());
  }

  static void verification(BuildContext context,
      {required String phone, required String otp}) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              VerificationScreen(phoneNumber: phone, expectedOtp: otp)),
    );
  }

  static void home(BuildContext context, {bool clearStack = true}) {
    final route = MaterialPageRoute(builder: (_) => const MainShell());
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

  static Future<bool?> orderDetail(BuildContext context,
      {required String orderId}) {
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

  static Future<void> analytics(BuildContext context) {
    return Navigator.of(context).push(
      _route(const AnalyticsScreen()),
    );
  }

  static Future<void> earnings(BuildContext context) {
    return Navigator.of(context).push(
      _route(const EarningsScreen()),
    );
  }

  static Future<void> operations(BuildContext context) {
    return Navigator.of(context).push(_route(const OperationsScreen()));
  }

  static Future<void> inventory(BuildContext context) {
    return Navigator.of(context).push(_route(const InventoryScreen()));
  }

  static Future<void> promotions(BuildContext context) {
    return Navigator.of(context).push(_route(const PromotionsScreen()));
  }

  static Future<void> staff(BuildContext context) {
    return Navigator.of(context).push(_route(const StaffScreen()));
  }

  static Future<void> reports(BuildContext context) {
    return Navigator.of(context).push(_route(const ReportsScreen()));
  }

  static Future<void> reviews(BuildContext context) {
    return Navigator.of(context).push(_route(const ReviewsScreen()));
  }

  static Future<void> notificationPrefs(BuildContext context) {
    return Navigator.of(context).push(_route(const NotificationPrefsScreen()));
  }

  static Future<void> kitchenDisplay(BuildContext context) {
    return Navigator.of(context).push(_route(const KitchenDisplayScreen()));
  }

  static Future<void> support(BuildContext context) {
    return Navigator.of(context).push(_route(const SupportScreen()));
  }

  static void _pushReplace(BuildContext context, Widget page) {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => page));
  }
}
