import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../navigation/seller_navigator.dart';
import '../widgets/common_widgets.dart';
import '../widgets/modern/glass_card.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {

  Map<String, dynamic>? _shop;
  int _pendingOrders = 0;
  int _totalMenuItems = 0;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;
  StreamSubscription? _realtimeSub;

  double _todayRevenue = 0;
  int _todayOrders = 0;
  double _weekRevenue = 0;
  double _avgRating = 0;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard().then((_) => _subscribeToRealtime());
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
            .select('id, total, delivery_address, delivery_phone, delivery_notes, created_at, status, Order_Items(name)')
            .eq('restaurant_id', shopId)
            .order('created_at', ascending: false)
            .limit(10);

        final items = await Supabase.instance.client
            .from('Menu_Items')
            .select('id')
            .eq('restaurant_id', shopId);

        final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toUtc().toIso8601String();
        final weekStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - DateTime.now().weekday + 1).toUtc().toIso8601String();

        final todayDelivered = await Supabase.instance.client
            .from('Orders')
            .select('total')
            .eq('restaurant_id', shopId)
            .eq('status', 'delivered')
            .gte('created_at', todayStart);

        final todayAll = await Supabase.instance.client
            .from('Orders')
            .select('id')
            .eq('restaurant_id', shopId)
            .gte('created_at', todayStart);

        final weekDelivered = await Supabase.instance.client
            .from('Orders')
            .select('total')
            .eq('restaurant_id', shopId)
            .eq('status', 'delivered')
            .gte('created_at', weekStart);

        final reviewsResult = await Supabase.instance.client
            .from('Reviews')
            .select('rating, comment, created_at')
            .eq('restaurant_id', shopId)
            .order('created_at', ascending: false)
            .limit(3);

        final reviewList = List<Map<String, dynamic>>.from(reviewsResult as List);
        final avgRating = reviewList.isEmpty ? 0.0 : reviewList.fold<double>(0, (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0)) / reviewList.length;

        final orderList = List<Map<String, dynamic>>.from(orders as List);
        final pending = orderList.where((o) => o['status'] == 'pending').toList();

        if (mounted) {
          setState(() {
            _shop = shop;
            _pendingOrders = pending.length;
            _totalMenuItems = (items as List).length;
            _recentOrders = orderList;
            _todayRevenue = todayDelivered.fold<double>(0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
            _todayOrders = (todayAll as List).length;
            _weekRevenue = weekDelivered.fold<double>(0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
            _avgRating = avgRating;
            _reviews = reviewList;
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

  void _subscribeToRealtime() {
    _realtimeSub?.cancel();
    if (_shop == null) return;
    final shopId = _shop!['id'];

    _realtimeSub = Supabase.instance.client
        .from('Orders')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', shopId)
        .listen((rows) {
      if (!mounted) return;
      final previousStatuses = <String, String>{};
      for (final o in _recentOrders) {
        if (o['id'] != null) previousStatuses[o['id'].toString()] = o['status']?.toString() ?? '';
      }

      _loadDashboard().then((_) {
        if (!mounted) return;
        for (final row in rows) {
          final id = row['id']?.toString() ?? '';
          final newStatus = row['status']?.toString() ?? '';
          final oldStatus = previousStatuses[id];
          if (oldStatus != null && oldStatus != newStatus) {
            _showStatusChangeNotification(id, oldStatus, newStatus);
          }
        }
      });
    });
  }

  void _showStatusChangeNotification(String orderId, String oldStatus, String newStatus) {
    final shortId = orderId.length > 8 ? '#${orderId.substring(0, 8)}' : '#$orderId';
    final label = _statusLabel(newStatus);
    final Color color = _statusColor(newStatus);
    final String message = _statusChangeMessage(oldStatus, newStatus);
    final IconData icon = _statusIcon(newStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$shortId — $label', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(message, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => SellerNavigator.orderDetail(context, orderId: orderId),
        ),
      ),
    );
  }

  String _statusChangeMessage(String old, String updated) {
    switch (updated) {
      case 'accepted':
        return 'Order has been accepted';
      case 'preparing':
        return 'Food is being prepared';
      case 'ready':
        return 'Order is ready for delivery';
      case 'delivered':
        return 'Order has been delivered';
      case 'cancelled':
        return 'Order was cancelled';
      default:
        return 'Status updated to $updated';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant_rounded;
      case 'ready':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline;
    }
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
      case 'pending':
        return AppColors.amber;
      case 'accepted':
        return AppColors.blue;
      case 'preparing':
        return AppColors.purple;
      case 'ready':
        return AppColors.green;
      case 'delivered':
        return AppColors.muted;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.muted;
    }
  }

  String _statusLabel(String s) => s[0].toUpperCase() + s.substring(1);

  String _orderItemsPreview(Map<String, dynamic> order) {
    final items = order['Order_Items'] as List?;
    if (items == null || items.isEmpty) return 'No items';
    final names = items.take(3).map((i) => i['name'] ?? '').where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return 'No items';
    final preview = names.join(', ');
    if (items.length > 3) return '$preview +${items.length - 3} more';
    return preview;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alee Seller', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 20)),
            if (_pendingOrders > 0) ...[
              const SizedBox(width: 8),
              _pendingBadge(_pendingOrders),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.muted),
            onPressed: () => SellerNavigator.profile(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.muted),
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
              color: AppColors.orange,
              child: _buildDashboard(),
            ),
    );
  }

  Widget _pendingBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildNoShop() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orangeLight, Color(0xFFFFE0D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.store_rounded, color: AppColors.orange, size: 44),
            ),
            const SizedBox(height: 28),
            const Text('Welcome to Alee Seller', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            const Text('Create your restaurant and start receiving orders', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => SellerNavigator.shopSetup(context),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Create Shop', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Revenue stats
        Row(
          children: [
            Expanded(child: _revenueCard('Today Revenue', 'Rs. ${_todayRevenue.toStringAsFixed(0)}', Icons.attach_money_rounded, AppColors.green)),
            const SizedBox(width: 10),
            Expanded(child: _revenueCard('Today Orders', '$_todayOrders', Icons.shopping_bag_rounded, AppColors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _revenueCard('Week Revenue', 'Rs. ${_weekRevenue.toStringAsFixed(0)}', Icons.trending_up_rounded, AppColors.purple)),
          ],
        ),
        const SizedBox(height: 20),

        // Shop card — premium gradient
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppGradients.dark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppColors.darkBg.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop['name'] ?? 'My Shop',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                shop['category'] ?? '',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.circle, color: AppColors.orange, size: 6),
                            const SizedBox(width: 8),
                            Text(
                              shop['address'] ?? '',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.orange, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  StatPill(icon: Icons.star_rounded, label: '${shop['rating'] ?? '4.5'}', bgColor: Colors.white.withOpacity(0.12)),
                  const SizedBox(width: 10),
                  StatPill(icon: Icons.access_time_rounded, label: shop['delivery_time'] ?? '25 min', bgColor: Colors.white.withOpacity(0.12)),
                  const SizedBox(width: 10),
                  StatPill(icon: Icons.delivery_dining, label: shop['delivery_fee'] ?? 'Free', bgColor: Colors.white.withOpacity(0.12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Stats — cleaner cards
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => SellerNavigator.orderManagement(context),
                child: _statCard('Pending', '$_pendingOrders', Icons.receipt_long_rounded, AppColors.orange),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => SellerNavigator.menuManagement(context),
                child: _statCard('Menu Items', '$_totalMenuItems', Icons.restaurant_menu_rounded, AppColors.green),
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
                child: Text('Pending Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              _sectionAction('View All', () => SellerNavigator.orderManagement(context)),
            ],
          ),
          const SizedBox(height: 14),
          ...pendingOrders.map((order) => _buildPendingOrderCard(order)),
          const SizedBox(height: 28),
        ],

        // Recent orders
        if (nonPendingOrders.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              _sectionAction('View All', () => SellerNavigator.orderManagement(context)),
            ],
          ),
          const SizedBox(height: 14),
          ...nonPendingOrders.map((order) => _buildRecentOrderCard(order)),
          const SizedBox(height: 28),
        ],

        // Quick actions
        const Text('Shop Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 14),
        ActionTile(icon: Icons.edit_rounded, title: 'Edit Shop Details', onTap: () => SellerNavigator.shopSetup(context)),
        ActionTile(icon: Icons.restaurant_menu_rounded, title: 'Manage Menu Items', onTap: () => SellerNavigator.menuManagement(context)),

        // Reviews
        if (_reviews.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 4),
                  Text(_avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._reviews.map((r) => _buildReviewCard(r)),
        ],

        if (pendingOrders.isEmpty && _recentOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.inbox_outlined,
              message: 'No orders yet',
            ),
          ),
      ],
    );
  }

  Widget _sectionAction(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPendingOrderCard(Map<String, dynamic> order) {
    final itemsPreview = _orderItemsPreview(order);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Order', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
                    if (itemsPreview != 'No items')
                      Text(itemsPreview, style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs. ${order['total'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.orange)),
                  const SizedBox(height: 2),
                  Text(_timeAgo(order['created_at']), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${order['delivery_address'] ?? 'N/A'}', style: const TextStyle(color: AppColors.muted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          if (order['delivery_notes'] != null && order['delivery_notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Note: ${order['delivery_notes']}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order['id'], 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.red),
                      ),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => SellerNavigator.orderDetail(context, orderId: order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.divider,
                    foregroundColor: AppColors.ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildRecentOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'delivered';
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? '#${orderId.substring(0, 8)}' : '#$orderId';
    final color = _statusColor(status);

    return GestureDetector(
      onTap: () => SellerNavigator.orderDetail(context, orderId: order['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(5)),
                        child: Text(shortId, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      ),
                      const SizedBox(width: 8),
                      Text('Rs. ${order['total'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_orderItemsPreview(order), style: const TextStyle(fontSize: 12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                        child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                      const SizedBox(width: 8),
                      Text(_timeAgo(order['created_at']), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9EAE))),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _revenueCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment'] ?? '';
    final createdAt = review['created_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < rating ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                size: 16,
              )),
              const SizedBox(width: 8),
              Text(_timeAgo(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          if (comment.toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment.toString(), style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
