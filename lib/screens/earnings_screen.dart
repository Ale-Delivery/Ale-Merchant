import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _loading = true;
  String? _shopId;

  double _todayEarnings = 0;
  double _weekEarnings = 0;
  double _monthEarnings = 0;
  double _lifetimeEarnings = 0;
  int _todayOrders = 0;
  int _weekOrders = 0;
  int _monthOrders = 0;
  int _lifetimeOrders = 0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final String userId = user.id;

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

      final allDelivered = await Supabase.instance.client
          .from('Orders')
          .select('total, created_at')
          .eq('restaurant_id', _shopId!)
          .eq('status', 'delivered')
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(allDelivered);

      _lifetimeEarnings = list.fold<double>(
          0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0));
      _lifetimeOrders = list.length;

      final todayDate = DateTime(now.year, now.month, now.day);
      final weekDate =
          todayDate.subtract(Duration(days: todayDate.weekday - 1));
      final monthDate = DateTime(now.year, now.month, 1);

      for (final o in list) {
        final created = _parseCreatedAt(o['created_at']);
        if (created == null) continue;
        if (!created.isBefore(todayDate)) {
          _todayEarnings += (o['total'] as num?)?.toDouble() ?? 0;
          _todayOrders++;
        }
        if (!created.isBefore(weekDate)) {
          _weekEarnings += (o['total'] as num?)?.toDouble() ?? 0;
          _weekOrders++;
        }
        if (!created.isBefore(monthDate)) {
          _monthEarnings += (o['total'] as num?)?.toDouble() ?? 0;
          _monthOrders++;
        }
      }

      _recentTransactions = list.take(20).toList();

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _parseCreatedAt(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Earnings',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildPeriodRow('Today', _todayEarnings, _todayOrders,
                      Icons.today_rounded, AppColors.orange),
                  const SizedBox(height: 12),
                  _buildPeriodRow('This Week', _weekEarnings, _weekOrders,
                      Icons.date_range_rounded, AppColors.blue),
                  const SizedBox(height: 12),
                  _buildPeriodRow('This Month', _monthEarnings, _monthOrders,
                      Icons.calendar_month_rounded, AppColors.purple),
                  const SizedBox(height: 12),
                  _buildPeriodRow('Lifetime', _lifetimeEarnings,
                      _lifetimeOrders, Icons.history_rounded, AppColors.green),
                  const SizedBox(height: 28),
                  const Text('Recent Transactions',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  if (_recentTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text('No transactions yet',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                    )
                  else
                    ..._recentTransactions.map((t) => _buildTransactionRow(t)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
              'Total Earnings',
              'Rs. ${_lifetimeEarnings.toStringAsFixed(0)}',
              Icons.account_balance_wallet_rounded,
              AppColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard('Orders', '$_lifetimeOrders',
              Icons.receipt_long_rounded, AppColors.orange),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(
      String label, double amount, int orders, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted)),
                Text('Rs. ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$orders orders',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> t) {
    final total = (t['total'] as num?)?.toDouble() ?? 0;
    final date = _formatTime(t['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order completed',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87)),
                Text(date,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Text('Rs. ${total.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange)),
        ],
      ),
    );
  }
}
