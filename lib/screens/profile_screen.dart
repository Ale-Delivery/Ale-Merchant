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
              .select('name')
              .eq('owner_id', _userId!)
              .maybeSingle();
          if (shop != null && mounted) {
            _shopName = shop['name'];
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
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
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? context.textPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('My Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppGradients.dark,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.avatar,
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                        ),
                        child: Center(
                          child: Text(
                            (_name ?? 'S').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name ?? 'Seller', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 6),
                            if (_phone != null)
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(_phone!, style: const TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            if (_shopName != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.store_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(_shopName!, style: const TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Account info
                if (_email != null || _gender != null || _birthday != null) ...[
                  _sectionHeader('Account Info'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        if (_email != null && _email!.isNotEmpty)
                          _infoRow(Icons.email_outlined, 'Email', _email!),
                        if (_gender != null && _gender!.isNotEmpty)
                          _infoRow(Icons.face_outlined, 'Gender', _gender!),
                        if (_birthday != null && _birthday!.isNotEmpty)
                          _infoRow(Icons.cake_outlined, 'Birthday', _birthday!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                _sectionHeader('Shop'),
                const SizedBox(height: 12),
                _menuTile(Icons.edit_rounded, 'Edit Shop Details', '', () => SellerNavigator.shopSetup(context)),
                _menuTile(Icons.restaurant_menu_rounded, 'Manage Menu', '', () => SellerNavigator.menuManagement(context)),
                _menuTile(Icons.receipt_long_rounded, 'Order Management', '', () => SellerNavigator.orderManagement(context)),
                const SizedBox(height: 28),

                _sectionHeader('Appearance'),
                const SizedBox(height: 12),
                _buildThemeSelector(),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
                    label: const Text('Log out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 16)),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.red.withOpacity(0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color ?? context.textHint;
    return Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: mutedColor, letterSpacing: 1.5));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? context.textPrimary;
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color ?? context.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: mutedColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? context.textPrimary;
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color ?? context.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: AppColors.orange, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                ),
                Icon(Icons.chevron_right_rounded, color: mutedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themeProvider = context.watch<ThemeProvider>();
    final current = themeProvider.themeMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _themeOption(
            icon: Icons.light_mode_rounded,
            title: 'Light',
            selected: current == ThemeMode.light,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          _themeOption(
            icon: Icons.dark_mode_rounded,
            title: 'Dark',
            selected: current == ThemeMode.dark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
          _themeOption(
            icon: Icons.phone_android_rounded,
            title: 'System',
            selected: current == ThemeMode.system,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color ?? context.textMuted;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? context.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.orange : mutedColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.orange : textColor,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.orange, size: 22),
          ],
        ),
      ),
    );
  }
}
