import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/seller_navigator.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  static const _primary = Color(0xFFFF6B35);
  static const _ink = Color(0xFF1E1E2C);
  static const _muted = Color(0xFF7D8491);

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
            child: const Text('Cancel', style: TextStyle(color: _muted, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: _ink, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E2C), Color(0xFF2E2E44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8C61), Color(0xFFFF6B35)],
                          ),
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
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
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
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    label: const Text('Log out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 16)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.06),
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
    return Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF9E9EAE), letterSpacing: 1.5));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _muted, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9D9DAF), fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
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
                  decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: _primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                ),
                const Icon(Icons.chevron_right_rounded, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
