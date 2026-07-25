import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../navigation/seller_navigator.dart';
import '../widgets/common_widgets.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  Map<String, dynamic>? _shop;
  String _userName = 'Seller';
  int _pendingOrders = 0;
  int _preparingOrders = 0;
  int _totalMenuItems = 0;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;
  StreamSubscription? _realtimeSub;

  double _todayRevenue = 0;
  int _todayOrders = 0;
  double _weekRevenue = 0;
  double _avgRating = 0;
  List<Map<String, dynamic>> _reviews = [];
  int _lowStockCount = 0;
  int _outStockCount = 0;

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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _loadDashboard() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final String userId = user.id;

    _userName = (await LocalStorageService.getUserName()) ?? 'Seller';

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
            .select(
                'id, total, delivery_address, delivery_phone, delivery_notes, created_at, status, Order_Items(name)')
            .eq('restaurant_id', shopId)
            .order('created_at', ascending: false)
            .limit(10);

        final items = await Supabase.instance.client
            .from('Menu_Items')
            .select('id')
            .eq('restaurant_id', shopId);

        final todayStart = DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .toUtc()
            .toIso8601String();
        final weekStart = DateTime(DateTime.now().year, DateTime.now().month,
                DateTime.now().day - DateTime.now().weekday + 1)
            .toUtc()
            .toIso8601String();

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

        int lowStock = 0, outStock = 0;
        try {
          final inv = await Supabase.instance.client
              .from('Menu_Items')
              .select('stock, low_stock_threshold')
              .eq('restaurant_id', shopId);
          for (final i in List<Map<String, dynamic>>.from(inv)) {
            final s = (i['stock'] as num?)?.toInt();
            if (s == null || s < 0) continue;
            if (s == 0) {
              outStock++;
              continue;
            }
            final t = (i['low_stock_threshold'] as num?)?.toInt() ?? 10;
            if (s <= t) lowStock++;
          }
        } catch (_) {}

        final reviewList =
            List<Map<String, dynamic>>.from(reviewsResult as List);
        final avgRating = reviewList.isEmpty
            ? 0.0
            : reviewList.fold<double>(
                    0,
                    (sum, r) =>
                        sum + ((r['rating'] as num?)?.toDouble() ?? 0)) /
                reviewList.length;

        final orderList = List<Map<String, dynamic>>.from(orders as List);
        final pending =
            orderList.where((o) => o['status'] == 'pending').toList();
        final preparing =
            orderList.where((o) => o['status'] == 'preparing').toList();

        if (mounted) {
          setState(() {
            _shop = shop;
            _pendingOrders = pending.length;
            _preparingOrders = preparing.length;
            _totalMenuItems = (items as List).length;
            _recentOrders = orderList;
            _todayRevenue = todayDelivered.fold<double>(
                0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
            _todayOrders = (todayAll as List).length;
            _weekRevenue = weekDelivered.fold<double>(
                0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
            _avgRating = avgRating;
            _reviews = reviewList;
            _lowStockCount = lowStock;
            _outStockCount = outStock;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeToRealtime() {
    _realtimeSub?.cancel();
    if (_shop == null) return;
    final shopId = _shop!['id'];
    _realtimeSub = Supabase.instance.client
        .from('Orders')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', shopId)
        .listen((_) {
          if (mounted) _loadDashboard();
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

  String _orderItemsPreview(Map<String, dynamic> order) {
    final items = order['Order_Items'] as List?;
    if (items == null || items.isEmpty) return 'No items';
    final names = items
        .take(3)
        .map((i) => i['name'] ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'No items';
    final preview = names.join(', ');
    if (items.length > 3) return '$preview +${items.length - 3} more';
    return preview;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _shop?['name'] ?? 'Dashboard',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_pendingOrders > 0)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: context.textPrimary),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$_pendingOrders',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                  color: context.textPrimary),
              onPressed: () {},
            ),
          IconButton(
            icon:
                Icon(Icons.person_outline_rounded, color: context.textPrimary),
            onPressed: () => SellerNavigator.profile(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : _shop == null
              ? _buildNoShop()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildGreeting(),
                      const SizedBox(height: 12),
                      _buildStatusBanner(),
                      const SizedBox(height: 12),
                      _buildInventoryAlert(),
                      const SizedBox(height: 12),
                      _buildStatsRow(),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      if (_pendingOrders > 0) ...[
                        _buildSectionTitle('Pending Orders',
                            trailing: _buildViewAll(() =>
                                SellerNavigator.orderManagement(context))),
                        const SizedBox(height: 12),
                        ..._pendingOrdersList(),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionTitle('Recent Orders',
                          trailing: _buildViewAll(
                              () => SellerNavigator.orderManagement(context))),
                      const SizedBox(height: 12),
                      ..._recentOrdersList(),
                      if (_reviews.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Customer Reviews'),
                        const SizedBox(height: 12),
                        ..._reviewsList(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInventoryAlert() {
    if (_lowStockCount == 0 && _outStockCount == 0)
      return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => SellerNavigator.inventory(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2_rounded,
                color: Color(0xFFE65100), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    '${_lowStockCount > 0 ? '$_lowStockCount low stock' : ''}${_lowStockCount > 0 && _outStockCount > 0 ? ' · ' : ''}${_outStockCount > 0 ? '$_outStockCount out of stock' : ''}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100))),
                const Text('Tap to manage inventory',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
              ])),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: Color(0xFFE65100)),
        ]),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isOpen = _shop?['is_open'] ?? true;
    return GestureDetector(
      onTap: () => SellerNavigator.operations(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.green.withValues(alpha: 0.08)
              : AppColors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen
                ? AppColors.green.withValues(alpha: 0.25)
                : AppColors.red.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? AppColors.green : AppColors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOpen
                    ? 'Open – Accepting Orders'
                    : 'Closed – Not accepting new orders',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOpen ? AppColors.green : AppColors.red,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: isOpen ? AppColors.green : AppColors.red),
          ],
        ),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.store_rounded,
                  color: AppColors.orange, size: 44),
            ),
            const SizedBox(height: 28),
            const Text('Welcome to Alee Seller',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87)),
            const SizedBox(height: 10),
            const Text('Create your restaurant and start receiving orders',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 15)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => SellerNavigator.shopSetup(context),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Create Shop',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final shopName = _shop?['name'] ?? 'My Shop';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()},',
          style: const TextStyle(
              fontSize: 14,
              color: AppColors.muted,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          shopName,
          style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
            child: _statCard('Today\'s Orders', '$_todayOrders',
                Icons.receipt_long_rounded, AppColors.orange)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                'Today\'s Revenue',
                'Rs. ${_todayRevenue.toStringAsFixed(0)}',
                Icons.attach_money_rounded,
                AppColors.green)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionChip(Icons.receipt_long_rounded, 'Orders', AppColors.blue,
            () => SellerNavigator.orderManagement(context)),
        const SizedBox(width: 10),
        _actionChip(Icons.restaurant_menu_rounded, 'Products', AppColors.purple,
            () => SellerNavigator.menuManagement(context)),
        const SizedBox(width: 10),
        _actionChip(Icons.bar_chart_rounded, 'Analytics', AppColors.green,
            () => SellerNavigator.analytics(context)),
        const SizedBox(width: 10),
        _actionChip(Icons.settings_rounded, 'Settings', AppColors.orange,
            () => SellerNavigator.shopSetup(context)),
      ],
    );
  }

  Widget _actionChip(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildViewAll(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: const Text('View All',
          style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    );
  }

  List<Widget> _pendingOrdersList() {
    final pending =
        _recentOrders.where((o) => o['status'] == 'pending').take(5).toList();
    return pending
        .map((order) => _buildOrderCard(order, isPending: true))
        .toList();
  }

  List<Widget> _recentOrdersList() {
    final nonPending =
        _recentOrders.where((o) => o['status'] != 'pending').take(5).toList();
    return nonPending.map((order) => _buildOrderCard(order)).toList();
  }

  List<Widget> _reviewsList() {
    return _reviews.map((r) => _buildReviewCard(r)).toList();
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {bool isPending = false}) {
    final status = order['status'] ?? '';
    final color = _statusColor(status);
    final orderId = order['id']?.toString() ?? '';
    final shortId =
        orderId.length > 8 ? '#${orderId.substring(0, 8)}' : '#$orderId';
    final itemsPreview = _orderItemsPreview(order);

    return GestureDetector(
      onTap: () async {
        final updated =
            await SellerNavigator.orderDetail(context, orderId: orderId);
        if (updated == true && mounted) _loadDashboard();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(shortId,
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (itemsPreview != 'No items') ...[
                    const SizedBox(height: 4),
                    Text(itemsPreview,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  Row(
                    children: [
                      Text('Rs. ${order['total'] ?? '0'}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange)),
                      const Spacer(),
                      Text(_timeAgo(order['created_at']),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.muted),
          ],
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < rating
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFD1D5DB),
                        size: 16,
                      )),
              const SizedBox(width: 8),
              Text(_timeAgo(createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          if (comment.toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment.toString(),
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
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
}
