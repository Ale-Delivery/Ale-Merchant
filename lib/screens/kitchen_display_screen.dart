import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
        final data = await Supabase.instance.client
            .from('Orders')
            .select(
                'id, status, created_at, Order_Items(name, quantity, selected_size)')
            .eq('restaurant_id', shop['id'])
            .order('created_at', ascending: true);
        if (mounted) {
          final active = (List<Map<String, dynamic>>.from(data))
              .where((o) => !['delivered', 'cancelled'].contains(o['status']))
              .toList();
          setState(() {
            _orders = active;
            _loading = false;
          });
        }

        _sub = Supabase.instance.client
            .from('Orders')
            .stream(primaryKey: ['id'])
            .eq('restaurant_id', shop['id'])
            .listen((_) {
              if (mounted) _load();
            });
      } else if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await Supabase.instance.client
        .from('Orders')
        .update({'status': status}).eq('id', id);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return AppColors.blue;
      case 'preparing':
        return AppColors.purple;
      case 'ready':
        return AppColors.green;
      default:
        return AppColors.muted;
    }
  }

  String _elapsed(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '<1m';
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final newOrders = _orders
        .where((o) => o['status'] == 'pending' || o['status'] == 'accepted')
        .toList();
    final preparing = _orders.where((o) => o['status'] == 'preparing').toList();
    final ready = _orders.where((o) => o['status'] == 'ready').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Text('Kitchen Display',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : DefaultTabController(
              length: 3,
              child: Column(children: [
                Container(
                  color: const Color(0xFF16213E),
                  child: TabBar(
                    indicatorColor: AppColors.orange,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: 'New (${newOrders.length})'),
                      Tab(text: 'Preparing (${preparing.length})'),
                      Tab(text: 'Ready (${ready.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(children: [
                    _buildOrderList(newOrders, 'new'),
                    _buildOrderList(preparing, 'preparing'),
                    _buildOrderList(ready, 'ready'),
                  ]),
                ),
              ]),
            ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String type) {
    if (orders.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, size: 64, color: Colors.white24),
        const SizedBox(height: 12),
        Text(
            type == 'new'
                ? 'All orders accepted'
                : type == 'preparing'
                    ? 'No orders in progress'
                    : 'No ready orders',
            style: const TextStyle(color: Colors.white38, fontSize: 16)),
      ]));
    }
    return Container(
      color: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final o = orders[i];
          final items = o['Order_Items'] as List? ?? [];
          final shortId = o['id'].toString().length > 6
              ? '#${o['id'].toString().substring(0, 6)}'
              : '#${o['id']}';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: type == 'new'
                      ? AppColors.orange.withValues(alpha: 0.3)
                      : type == 'preparing'
                          ? AppColors.purple.withValues(alpha: 0.3)
                          : AppColors.green.withValues(alpha: 0.3),
                  width: 1.5),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(shortId,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _statusColor(o['status']).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_elapsed(o['created_at']),
                      style: TextStyle(
                          color: _statusColor(o['status']),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text('${item['quantity'] ?? 1}x',
                                style: const TextStyle(
                                    color: AppColors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(item['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  )),
              const SizedBox(height: 12),
              if (type == 'new')
                Row(children: [
                  Expanded(
                      child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(o['id'], 'preparing'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text('Start Prep',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700))))),
                ])
              else if (type == 'preparing')
                Row(children: [
                  Expanded(
                      child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                              onPressed: () => _updateStatus(o['id'], 'ready'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text('Mark Ready',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700))))),
                ])
              else if (type == 'ready')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle, color: AppColors.green, size: 16),
                    SizedBox(width: 6),
                    Text('Ready for pickup',
                        style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                ),
            ]),
          );
        },
      ),
    );
  }
}
