import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../navigation/seller_navigator.dart';
import '../widgets/common_widgets.dart';

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
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _subscribeToNewOrders();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select()
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop != null) {
        final shopId = shop['id'];
        final orders = await Supabase.instance.client
            .from('Orders')
            .select('id, total, delivery_address, delivery_phone, delivery_notes, created_at, status')
            .eq('restaurant_id', shopId)
            .order('created_at', ascending: false)
            .limit(10);

        final items = await Supabase.instance.client
            .from('Menu_Items')
            .select('id')
            .eq('restaurant_id', shopId);

        final pending = (orders as List)
            .where((o) => o['status'] == 'pending')
            .toList();

        if (mounted) {
          setState(() {
            _shop = shop;
            _pendingOrders = pending.length;
            _totalMenuItems = (items as List).length;
            _recentOrders = List<Map<String, dynamic>>.from(orders);
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

  Future<void> _updateOrderStatus(String orderId, String status) async {
    await Supabase.instance.client
        .from('Orders')
        .update({'status': status})
        .eq('id', orderId);
    _loadDashboard();
  }

  void _subscribeToNewOrders() {
    _realtimeSub?.cancel();
    _realtimeSub = Supabase.instance.client
        .from('Orders')
        .stream(primaryKey: ['id'])
        .listen((rows) {
      if (!mounted || _shop == null) return;
      _loadDashboard();
    });
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'accepted': return const Color(0xFF3B82F6);
      case 'preparing': return const Color(0xFF8B5CF6);
      case 'ready': return const Color(0xFF10B981);
      case 'delivered': return const Color(0xFF6B7280);
      default: return _muted;
    }
  }

  String _statusLabel(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _primary)));
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alee Seller', style: TextStyle(color: _ink, fontWeight: FontWeight.w800)),
            if (_pendingOrders > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingOrders',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: _muted),
            onPressed: () => SellerNavigator.profile(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _muted),
            onPressed: () async {
              await LocalStorageService.clearSession();
              if (mounted) SellerNavigator.phoneAuth(context);
            },
          ),
        ],
      ),
      body: _shop == null
          ? _buildNoShop()
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              color: _primary,
              child: _buildDashboard(),
            ),
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(24),
              ),
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
                backgroundColor: _primary,
                foregroundColor: Colors.white,
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
    final pendingOrders = _recentOrders.where((o) => o['status'] == 'pending').toList();
    final nonPendingOrders = _recentOrders.where((o) => o['status'] != 'pending').take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
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
                    child: Text(
                      shop['name'] ?? 'My Shop',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                shop['category'] ?? '',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatPill(
                    icon: Icons.star_rounded,
                    label: '${shop['rating'] ?? 'N/A'}',
                    bgColor: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 10),
                  StatPill(
                    icon: Icons.access_time_rounded,
                    label: shop['delivery_time'] ?? 'N/A',
                    bgColor: Colors.white.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Stats cards
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => SellerNavigator.orderManagement(context),
                child: StatCard(
                  label: 'Pending Orders',
                  value: '$_pendingOrders',
                  icon: Icons.receipt_long_rounded,
                  bgColor: const Color(0xFFFFF3EE),
                  fgColor: _primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => SellerNavigator.menuManagement(context),
                child: StatCard(
                  label: 'Menu Items',
                  value: '$_totalMenuItems',
                  icon: Icons.restaurant_menu_rounded,
                  bgColor: const Color(0xFFEAF8EF),
                  fgColor: const Color(0xFF299653),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Pending orders — quick accept/reject
        if (pendingOrders.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: Text('Pending Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
              ),
              TextButton(
                onPressed: () => SellerNavigator.orderManagement(context),
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pendingOrders.map((order) => _buildPendingOrderCard(order)),
          const SizedBox(height: 24),
        ],

        // Recent orders (non-pending)
        if (nonPendingOrders.isNotEmpty) ...[
          const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 12),
          ...nonPendingOrders.map((order) => _buildRecentOrderCard(order)),
          const SizedBox(height: 24),
        ],

        // Quick actions
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 14),
        ActionTile(
          icon: Icons.edit_rounded,
          title: 'Edit Shop Details',
          onTap: () => SellerNavigator.shopSetup(context),
        ),
        ActionTile(
          icon: Icons.restaurant_menu_rounded,
          title: 'Manage Menu Items',
          onTap: () => SellerNavigator.menuManagement(context),
        ),
        if (pendingOrders.isEmpty && _recentOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Icon(Icons.inbox_outlined, color: Color(0xFF7D8491), size: 48),
            ),
          ),
      ],
    );
  }

  Widget _buildPendingOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New Order — Rs. ${order['total'] ?? '0'}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink),
                ),
              ),
              Text(
                _timeAgo(order['created_at']),
                style: const TextStyle(color: Color(0xFF7D8491), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order['delivery_address'] ?? 'N/A'}',
            style: const TextStyle(color: Color(0xFF7D8491), fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (order['delivery_notes'] != null && order['delivery_notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Note: ${order['delivery_notes']}',
                style: const TextStyle(color: Color(0xFF9E9EAE), fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order['id'], 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () => SellerNavigator.orderDetail(context, orderId: order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: _ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'delivered';
    return GestureDetector(
      onTap: () => SellerNavigator.orderDetail(context, orderId: order['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long_rounded, color: _statusColor(status), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rs. ${order['total'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
                  Text(
                    '${_statusLabel(status)} · ${_timeAgo(order['created_at'])}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7D8491)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC0C0D0), size: 18),
          ],
        ),
      ),
    );
  }
}
