import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../navigation/seller_navigator.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  static const _primary = Color(0xFFFF6B35);
  static const _ink = Color(0xFF1E1E2C);
  static const _muted = Color(0xFF7D8491);
  static const _surface = Color(0xFFF7F8FA);

  Map<String, dynamic>? _shop;
  int _pendingOrders = 0;
  int _totalMenuItems = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      final shop = await Supabase.instance.client.from('Restaurants').select().eq('owner_id', userId).maybeSingle();
      if (shop != null) {
        final orders = await Supabase.instance.client.from('Orders').select('id').eq('restaurant_id', shop['id']).eq('status', 'pending');
        final items = await Supabase.instance.client.from('Menu_Items').select('id').eq('restaurant_id', shop['id']);

        if (mounted) {
          setState(() {
            _shop = shop;
            _pendingOrders = (orders as List).length;
            _totalMenuItems = (items as List).length;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _primary)));
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Alee Seller', style: TextStyle(color: _ink, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: _muted), onPressed: () async {
            await LocalStorageService.clearSession();
            if (mounted) SellerNavigator.phoneAuth(context);
          }),
        ],
      ),
      body: _shop == null ? _buildNoShop() : _buildDashboard(),
    );
  }

  Widget _buildNoShop() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFFFF3EE), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.store_rounded, color: _primary, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('No Shop Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            const Text('Create your restaurant to start receiving orders', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 14)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => SellerNavigator.shopSetup(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Shop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final shop = _shop!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(shop['name'] ?? 'My Shop', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 6),
                Text(shop['category'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statPill(Icons.star_rounded, '${shop['rating'] ?? 'N/A'}', Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 10),
                    _statPill(Icons.access_time_rounded, shop['delivery_time'] ?? 'N/A', Colors.white.withOpacity(0.2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards
          Row(
            children: [
              Expanded(child: _statCard('Pending Orders', '$_pendingOrders', Icons.receipt_long_rounded, const Color(0xFFFFF3EE), _primary)),
              const SizedBox(width: 14),
              Expanded(child: _statCard('Menu Items', '$_totalMenuItems', Icons.restaurant_menu_rounded, const Color(0xFFEAF8EF), const Color(0xFF299653))),
            ],
          ),
          const SizedBox(height: 28),

          // Quick actions
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 14),
          _actionTile(Icons.edit_rounded, 'Edit Shop Details', () => SellerNavigator.shopSetup(context)),
          _actionTile(Icons.restaurant_menu_rounded, 'Manage Menu Items', () => SellerNavigator.menuManagement(context)),
          _actionTile(Icons.receipt_long_rounded, 'View Orders ($_pendingOrders pending)', () => SellerNavigator.orderManagement(context)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: fg, size: 20)),
          const SizedBox(height: 14),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [Icon(icon, color: _primary, size: 22), const SizedBox(width: 14), Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink))), const Icon(Icons.chevron_right_rounded, color: _muted)]),
          ),
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white70, size: 14), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
    );
  }
}
