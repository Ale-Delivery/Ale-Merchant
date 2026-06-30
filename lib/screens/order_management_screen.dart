import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../navigation/seller_navigator.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filterStatus = 'pending';
  String _dateFilter = 'all';

  final List<String> _statusOptions = ['pending', 'accepted', 'preparing', 'ready', 'delivered'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      final shop = await Supabase.instance.client.from('Restaurants').select('id').eq('owner_id', userId).maybeSingle();
      if (shop != null) {
        var query = Supabase.instance.client.from('Orders').select().eq('restaurant_id', shop['id']);
        if (_filterStatus != 'all') {
          query = query.eq('status', _filterStatus);
        }
        if (_dateFilter == 'today') {
          final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toUtc().toIso8601String();
          query = query.gte('created_at', todayStart);
        }
        final orders = await query.order('created_at', ascending: false);
        if (mounted) setState(() { _orders = List<Map<String, dynamic>>.from(orders); _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await Supabase.instance.client.from('Orders').update({'status': status}).eq('id', orderId);
    await _loadOrders();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.amber;
      case 'accepted': return AppColors.blue;
      case 'preparing': return AppColors.purple;
      case 'ready': return AppColors.green;
      case 'delivered': return AppColors.muted;
      default: return AppColors.muted;
    }
  }

  String _statusLabel(String status) => status[0].toUpperCase() + status.substring(1);

  Widget _datePill(String label, String value) {
    final selected = value == _dateFilter;
    return GestureDetector(
      onTap: () {
        setState(() => _dateFilter = value);
        _loadOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.orange : context.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Orders', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              itemBuilder: (_, i) {
                final s = _statusOptions[i];
                final selected = s == _filterStatus;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_statusLabel(s), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : context.textPrimary)),
                    selected: selected,
                    onSelected: (_) { setState(() => _filterStatus = s); _loadOrders(); },
                    selectedColor: _statusColor(s),
                    backgroundColor: context.surfaceColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: selected ? _statusColor(s) : context.cardBorder),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Date filter row
          Container(
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _datePill('All Time', 'all'),
                const SizedBox(width: 8),
                _datePill('Today', 'today'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Orders list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _orders.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_rounded,
                        message: 'No ${_statusLabel(_filterStatus)} orders',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) {
                          final order = _orders[i];
                          final status = order['status'] ?? 'pending';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final updated = await SellerNavigator.orderDetail(context, orderId: order['id']);
                                if (updated == true && mounted) _loadOrders();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text('Order #${order['id']?.toString().substring(0, 8) ?? ''}', style: TextStyle(fontWeight: FontWeight.w800, color: context.textPrimary))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                        child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Text('Rs. ${order['total']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.orange)),
                                    const SizedBox(height: 6),
                                    Text('Address: ${order['delivery_address'] ?? 'N/A'}', style: TextStyle(color: context.textMuted, fontSize: 12)),
                                    if (order['delivery_notes'] != null && order['delivery_notes'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('Notes: ${order['delivery_notes']}', style: TextStyle(color: context.textMuted, fontSize: 12)),
                                    ],
                                    const SizedBox(height: 12),
                                    if (status == 'pending')
                                  Row(children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _updateStatus(order['id'], 'accepted'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _updateStatus(order['id'], 'delivered'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ])
                                else if (status == 'accepted')
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(order['id'], 'preparing'),
                                    icon: const Icon(Icons.thumb_up, size: 16),
                                    label: const Text('Start Preparing'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white),
                                  )
                                else if (status == 'preparing')
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(order['id'], 'ready'),
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: const Text('Mark Ready'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white),
                                  )
                                else if (status == 'ready')
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(order['id'], 'delivered'),
                                    icon: const Icon(Icons.delivery_dining, size: 16),
                                    label: const Text('Mark Delivered'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.muted, foregroundColor: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
