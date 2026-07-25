import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../navigation/seller_navigator.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;
  String? _shopId;

  double _todaySales = 0;
  double _weekSales = 0;
  double _monthSales = 0;
  int _todayOrders = 0;
  int _weekOrders = 0;
  int _monthOrders = 0;
  int _completedOrders = 0;
  int _cancelledOrders = 0;
  int _totalOrders = 0;
  double _avgPrepTime = 0;
  double _avgRating = 0;
  int _ratingCount = 0;
  List<Map<String, dynamic>> _popularItems = [];
  Map<int, int> _hourlyOrders = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      _shopId = shop['id'];

      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1)
          .toUtc()
          .toIso8601String();
      final monthStart =
          DateTime(now.year, now.month, 1).toUtc().toIso8601String();

      await Future.wait([
        _loadSales('today', todayStart),
        _loadSales('week', weekStart),
        _loadSales('month', monthStart),
        _loadPopularItems(),
        _loadRatings(),
      ]);

      final allOrders = await Supabase.instance.client
          .from('Orders')
          .select('status, created_at')
          .eq('restaurant_id', _shopId!);

      if (mounted) {
        final list = List<Map<String, dynamic>>.from(allOrders);
        _completedOrders = list.where((o) => o['status'] == 'delivered').length;
        _cancelledOrders = list.where((o) => o['status'] == 'cancelled').length;
        _totalOrders = list.length;

        for (final o in list) {
          final created = o['created_at'] as String?;
          if (created != null) {
            final dt = DateTime.tryParse(created);
            if (dt != null) {
              final hour = dt.hour;
              _hourlyOrders[hour] = (_hourlyOrders[hour] ?? 0) + 1;
            }
          }
        }

        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSales(String period, String start) async {
    if (_shopId == null) return;
    final data = await Supabase.instance.client
        .from('Orders')
        .select('total')
        .eq('restaurant_id', _shopId!)
        .eq('status', 'delivered')
        .gte('created_at', start);

    final list = List<Map<String, dynamic>>.from(data);
    final total = list.fold<double>(
        0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0));
    final count = list.length;

    if (mounted) {
      setState(() {
        switch (period) {
          case 'today':
            _todaySales = total;
            _todayOrders = count;
          case 'week':
            _weekSales = total;
            _weekOrders = count;
          case 'month':
            _monthSales = total;
            _monthOrders = count;
        }
      });
    }
  }

  Future<void> _loadPopularItems() async {
    if (_shopId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('Order_Items')
          .select('name, quantity')
          .eq(
              'order_id',
              Supabase.instance.client
                  .from('Orders')
                  .select('id')
                  .eq('restaurant_id', _shopId!))
          .order('quantity', ascending: false)
          .limit(5);

      if (mounted) {
        _popularItems = List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
  }

  Future<void> _loadRatings() async {
    if (_shopId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('Reviews')
          .select('rating')
          .eq('restaurant_id', _shopId!);

      final list = List<Map<String, dynamic>>.from(data);
      _ratingCount = list.length;
      if (list.isNotEmpty) {
        _avgRating = list.fold<double>(
                0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
            list.length;
      }
    } catch (_) {}
  }

  double get _completionRate =>
      _totalOrders > 0 ? (_completedOrders / _totalOrders) * 100 : 0;
  double get _cancellationRate =>
      _totalOrders > 0 ? (_cancelledOrders / _totalOrders) * 100 : 0;

  List<int> get _peakHours {
    final sorted = _hourlyOrders.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Analytics',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.trending_up_rounded, color: AppColors.orange),
            onPressed: () => SellerNavigator.earnings(context),
            tooltip: 'View Earnings',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _buildSalesSummary(),
                  const SizedBox(height: 20),
                  _buildPerformanceCards(),
                  const SizedBox(height: 20),
                  _buildPopularItems(),
                  if (_peakHours.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildPeakHours(),
                  ],
                  const SizedBox(height: 20),
                  _buildRatingCard(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => SellerNavigator.earnings(context),
                      icon: const Icon(Icons.trending_up_rounded, size: 20),
                      label: const Text('View Full Earnings',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: BorderSide(
                            color: AppColors.orange.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSalesSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sales Overview',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _miniCard(
                    'Today',
                    'Rs. ${_todaySales.toStringAsFixed(0)}',
                    '$_todayOrders orders',
                    AppColors.orange)),
            const SizedBox(width: 10),
            Expanded(
                child: _miniCard(
                    'This Week',
                    'Rs. ${_weekSales.toStringAsFixed(0)}',
                    '$_weekOrders orders',
                    AppColors.blue)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _miniCard(
                    'This Month',
                    'Rs. ${_monthSales.toStringAsFixed(0)}',
                    '$_monthOrders orders',
                    AppColors.purple)),
            const SizedBox(width: 10),
            Expanded(
                child: _miniCard('Avg. Rating', _avgRating.toStringAsFixed(1),
                    '$_ratingCount reviews', const Color(0xFFF59E0B))),
          ],
        ),
      ],
    );
  }

  Widget _miniCard(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              label == 'Today'
                  ? Icons.today_rounded
                  : label == 'This Week'
                      ? Icons.date_range_rounded
                      : label == 'Avg. Rating'
                          ? Icons.star_rounded
                          : Icons.calendar_month_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPerformanceCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Performance',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _perfCard(
                    'Completed',
                    '$_completedOrders',
                    '${_completionRate.toStringAsFixed(0)}%',
                    AppColors.green,
                    Icons.check_circle_rounded)),
            const SizedBox(width: 10),
            Expanded(
                child: _perfCard(
                    'Cancelled',
                    '$_cancelledOrders',
                    '${_cancellationRate.toStringAsFixed(0)}%',
                    AppColors.red,
                    Icons.cancel_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _perfCard(
      String label, String count, String rate, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(rate,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Popular Products',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 12),
        if (_popularItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('No product data available yet',
                  style: TextStyle(color: AppColors.muted)),
            ),
          )
        else
          ...List.generate(_popularItems.length, (i) {
            final item = _popularItems[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87)),
                  ),
                  Text('${item['quantity'] ?? 0} sold',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPeakHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Peak Hours',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: _peakHours.asMap().entries.map((e) {
              final hour = e.value;
              final label = hour < 12
                  ? '${hour}AM'
                  : hour == 12
                      ? '12PM'
                      : '${hour - 12}PM';
              final amPm = hour < 12 ? 'AM' : 'PM';
              final displayHour = hour == 0
                  ? 12
                  : hour > 12
                      ? hour - 12
                      : hour;
              final count = _hourlyOrders[hour] ?? 0;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('$displayHour',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.orange,
                                fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(amPm,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted)),
                    Text('$count orders',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star_rounded,
                color: Color(0xFFF59E0B), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87)),
                Text('$_ratingCount reviews',
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Icon(
                i < _avgRating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < _avgRating.round()
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFD1D5DB),
                size: 20,
              );
            }),
          ),
        ],
      ),
    );
  }
}
