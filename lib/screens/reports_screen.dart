import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  String? _shopId;
  double _grossSales = 0;
  int _orderCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  double _avgOrderValue = 0;
  String _period = 'Today';
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_period) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Yesterday':
        return DateTime(now.year, now.month, now.day - 1);
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Custom':
        return _customStart ?? DateTime(now.year, now.month, now.day);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    if (_period == 'Yesterday')
      return DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
    if (_period == 'Custom') return _customEnd ?? now;
    return now;
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final String userId = user.id;
    try {
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop != null) {
        _shopId = shop['id'];
        final orders = await Supabase.instance.client
            .from('Orders')
            .select('total, status')
            .eq('restaurant_id', _shopId!)
            .gte('created_at', _startDate.toUtc().toIso8601String())
            .lte('created_at', _endDate.toUtc().toIso8601String());

        final list = List<Map<String, dynamic>>.from(orders);
        _orderCount = list.length;
        _completedCount = list.where((o) => o['status'] == 'delivered').length;
        _cancelledCount = list.where((o) => o['status'] == 'cancelled').length;
        _grossSales = list.fold<double>(
            0, (s, o) => s + ((o['total'] as num?)?.toDouble() ?? 0));
        _avgOrderValue =
            _completedCount > 0 ? _grossSales / _completedCount : 0;
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Sales Reports',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _statCard(
                        'Gross Sales',
                        'Rs. ${_grossSales.toStringAsFixed(0)}',
                        Icons.attach_money_rounded,
                        AppColors.green),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _statCard('Orders', '$_orderCount',
                              Icons.receipt_long_rounded, AppColors.orange)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard('Completed', '$_completedCount',
                              Icons.check_circle_rounded, AppColors.green)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _statCard('Cancelled', '$_cancelledCount',
                              Icons.cancel_rounded, AppColors.red)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                              'Avg Order',
                              'Rs. ${_avgOrderValue.toStringAsFixed(0)}',
                              Icons.trending_up_rounded,
                              AppColors.blue)),
                    ]),
                  ]),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'Yesterday', 'This Week', 'This Month'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Select Period',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: periods.map((p) {
              final selected = _period == p;
              return GestureDetector(
                onTap: () {
                  _period = p;
                  _load();
                },
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: selected
                            ? AppColors.orange
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(p,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.black87))),
              );
            }).toList()),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
      ]),
    );
  }
}
