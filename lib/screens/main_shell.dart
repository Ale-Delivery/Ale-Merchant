import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'home_screen.dart';
import 'order_management_screen.dart';
import 'menu_management_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SellerHomeScreen(),
    const OrderManagementScreen(),
    const MenuManagementScreen(),
    const NotificationsScreen(),
    const SellerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.orange,
            unselectedItemColor: AppColors.muted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_rounded),
                  label: 'Notifications'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
