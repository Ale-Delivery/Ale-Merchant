import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/seller_navigator.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  String? _name;
  String? _phone;
  String? _email;
  String? _gender;
  String? _birthday;
  String? _userId;
  String? _shopName;
  String? _shopImage;
  String? _shopCategory;
  bool? _shopOpen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final name = await LocalStorageService.getUserName();
    final phone = await LocalStorageService.getUserPhone();
    final savedUserId = await LocalStorageService.getUserId();

    if (phone != null) {
      final authService = AuthService();
      final profile = await authService.getUserProfile(phone);
      if (profile != null && mounted) {
        setState(() {
          _name = profile['name'] ?? name ?? 'Seller';
          _phone = phone;
          _email = profile['email'];
          _gender = profile['gender'];
          _birthday = profile['birthday'];
          _userId = profile['id']?.toString() ?? savedUserId;
        });
      }
    }

    if (mounted) {
      _name ??= name ?? 'Seller';
      _phone ??= phone;
      _userId ??= savedUserId;

      if (_userId != null) {
        try {
          final shop = await Supabase.instance.client
              .from('Restaurants')
              .select('name, image_url, category, is_open')
              .eq('owner_id', _userId!)
              .maybeSingle();
          if (shop != null && mounted) {
            _shopName = shop['name'];
            _shopImage = shop['image_url'];
            _shopCategory = shop['category'];
            _shopOpen = shop['is_open'] ?? true;
          }
        } catch (_) {}
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: context.textMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await LocalStorageService.clearSession();
    if (!mounted) return;
    SellerNavigator.phoneAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Profile',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildShopCard(),
                const SizedBox(height: 20),
                _buildMenuSection('Shop Management', [
                  _menuTile(Icons.edit_rounded, 'Store Settings',
                      () => SellerNavigator.shopSetup(context)),
                  _menuTile(Icons.settings_rounded, 'Operations',
                      () => SellerNavigator.operations(context)),
                  _menuTile(Icons.inventory_2_rounded, 'Inventory',
                      () => SellerNavigator.inventory(context)),
                  _menuTile(Icons.local_offer_rounded, 'Promotions',
                      () => SellerNavigator.promotions(context)),
                  _menuTile(Icons.people_rounded, 'Staff Accounts',
                      () => SellerNavigator.staff(context)),
                  _menuTile(Icons.restaurant_menu_rounded, 'Manage Products',
                      () => SellerNavigator.menuManagement(context)),
                  _menuTile(Icons.receipt_long_rounded, 'Order Management',
                      () => SellerNavigator.orderManagement(context)),
                  _menuTile(Icons.dining_rounded, 'Kitchen Display',
                      () => SellerNavigator.kitchenDisplay(context)),
                ]),
                const SizedBox(height: 20),
                _buildMenuSection('Business Insights', [
                  _menuTile(Icons.bar_chart_rounded, 'Analytics',
                      () => SellerNavigator.analytics(context)),
                  _menuTile(Icons.trending_up_rounded, 'Earnings',
                      () => SellerNavigator.earnings(context)),
                  _menuTile(Icons.assessment_rounded, 'Sales Reports',
                      () => SellerNavigator.reports(context)),
                  _menuTile(Icons.star_rounded, 'Customer Reviews',
                      () => SellerNavigator.reviews(context)),
                ]),
                const SizedBox(height: 20),
                _buildMenuSection('Settings & Support', [
                  _menuTile(Icons.notifications_rounded, 'Notifications',
                      () => SellerNavigator.notificationPrefs(context)),
                  _menuTile(Icons.help_center_rounded, 'Help & Support',
                      () => SellerNavigator.support(context)),
                ]),
                const SizedBox(height: 20),
                _buildMenuSection('Appearance', [
                  _buildThemeToggle(context),
                ]),
                const SizedBox(height: 20),
                if (_email != null || _gender != null || _birthday != null)
                  _buildMenuSection('Account Info', [
                    if (_email != null && _email!.isNotEmpty)
                      _infoRow(Icons.email_outlined, _email!),
                    if (_gender != null && _gender!.isNotEmpty)
                      _infoRow(Icons.face_outlined, _gender!),
                    if (_birthday != null && _birthday!.isNotEmpty)
                      _infoRow(Icons.cake_outlined, _birthday!),
                  ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.red, size: 20),
                    label: const Text('Log out',
                        style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.red, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.avatar,
            ),
            child: Center(
              child: Text(
                (_name ?? 'S').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name ?? 'Seller',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                if (_phone != null)
                  Text(_phone!,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.muted)),
                if (_shopName != null)
                  Text(_shopName!,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _shopImage != null && _shopImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(_shopImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.store_rounded,
                            color: AppColors.orange,
                            size: 26)),
                  )
                : const Icon(Icons.store_rounded,
                    color: AppColors.orange, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_shopName ?? 'My Shop',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                if (_shopCategory != null && _shopCategory!.isNotEmpty)
                  Text(_shopCategory!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _shopOpen == true
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _shopOpen == true ? 'Open' : 'Closed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _shopOpen == true
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.orange, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.muted, size: 18),
          ),
          const SizedBox(width: 14),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return InkWell(
      onTap: () {
        final next = themeProvider.themeMode == ThemeMode.light
            ? ThemeMode.dark
            : themeProvider.themeMode == ThemeMode.dark
                ? ThemeMode.system
                : ThemeMode.light;
        themeProvider.setThemeMode(next);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : themeProvider.themeMode == ThemeMode.system
                        ? Icons.phone_android_rounded
                        : Icons.light_mode_rounded,
                color: AppColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  Text(
                    themeProvider.themeMode == ThemeMode.light
                        ? 'Light'
                        : themeProvider.themeMode == ThemeMode.dark
                            ? 'Dark'
                            : 'System',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
