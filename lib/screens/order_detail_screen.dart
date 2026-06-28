import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {

  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await Supabase.instance.client
          .from('Orders')
          .select()
          .eq('id', widget.orderId)
          .maybeSingle();

      if (order == null) {
        if (mounted) setState(() { _error = 'Order not found'; _loading = false; });
        return;
      }

      final items = await Supabase.instance.client
          .from('Order_Items')
          .select()
          .eq('order_id', widget.orderId);

      if (mounted) {
        setState(() {
          _order = order;
          _items = List<Map<String, dynamic>>.from(items);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _updateStatus(String status) async {
    await Supabase.instance.client
        .from('Orders')
        .update({'status': status})
        .eq('id', widget.orderId);

    setState(() {
      _order!['status'] = status;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.amber;
      case 'accepted': return AppColors.blue;
      case 'preparing': return AppColors.purple;
      case 'ready': return AppColors.green;
      case 'delivered': return AppColors.muted;
      case 'cancelled': return AppColors.red;
      default: return AppColors.muted;
    }
  }

  String _statusLabel(String status) => status[0].toUpperCase() + status.substring(1);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.muted, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      );
    }

    final order = _order!;
    final status = order['status'] ?? 'pending';
    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Order #${order['id']?.toString().substring(0, 8) ?? ''}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.12), statusColor.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(status), color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusLabel(status), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: statusColor)),
                    const SizedBox(height: 2),
                    Text(_statusSubtitle(status), style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Delivery info
          _sectionCard('Delivery Info', children: [
            _infoRow(Icons.location_on_outlined, 'Address', order['delivery_address'] ?? 'N/A'),
            if (order['delivery_phone'] != null && order['delivery_phone'].toString().isNotEmpty)
              _infoRow(Icons.phone_outlined, 'Phone', order['delivery_phone']),
            _infoRow(Icons.payment_outlined, 'Payment', (order['payment_method'] ?? 'cash') == 'cash' ? 'Cash on Delivery' : order['payment_method'] ?? 'Cash'),
            if (order['delivery_notes'] != null && order['delivery_notes'].toString().isNotEmpty)
              _infoRow(Icons.note_outlined, 'Notes', order['delivery_notes'].toString()),
          ]),
          const SizedBox(height: 16),

          // Items
          _sectionCard('Order Items (${_items.length})', children: [
            ..._items.map((item) {
              final name = item['name'] ?? '';
              final qty = item['quantity'] ?? 0;
              final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
              final size = item['selected_size']?.toString();
              final image = item['image_url']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 52, height: 52,
                        color: AppColors.divider,
                        child: image.isNotEmpty
                            ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: AppColors.muted, size: 22))
                            : const Icon(Icons.fastfood, color: AppColors.muted, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(
                            '${size != null ? '$size · ' : ''}${qty}x',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text('Rs. ${(price * (qty is int ? qty : 1)).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                  ],
                ),
              );
            }),
            const Divider(height: 20, color: AppColors.border),
            _priceRow('Subtotal', 'Rs. ${(order['subtotal'] ?? 0).toString()}'),
            const SizedBox(height: 8),
            _priceRow('Delivery Fee', 'Rs. ${(order['delivery_fee'] ?? 0).toString()}'),
            const SizedBox(height: 10),
            _priceRow('Total', 'Rs. ${(order['total'] ?? 0).toString()}', bold: true),
          ]),
          const SizedBox(height: 24),

          // Action buttons
          if (status == 'pending')
            _actionRow([
              _actionBtn('Accept', Icons.check_circle_outline, AppColors.green, () => _updateStatus('accepted')),
              _actionBtn('Reject', Icons.cancel_outlined, AppColors.red, () => _updateStatus('cancelled'), outlined: true),
            ])
          else if (status == 'accepted')
            _actionBtn('Start Preparing', Icons.restaurant_rounded, AppColors.purple, () => _updateStatus('preparing'))
          else if (status == 'preparing')
            _actionBtn('Mark Ready', Icons.check_circle_outline, AppColors.green, () => _updateStatus('ready'))
          else if (status == 'ready')
            _actionBtn('Mark Delivered', Icons.delivery_dining, AppColors.muted, () => _updateStatus('delivered')),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'accepted': return Icons.check_circle_outline;
      case 'preparing': return Icons.restaurant_rounded;
      case 'ready': return Icons.delivery_dining;
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.info_outline;
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'pending': return 'Awaiting your response';
      case 'accepted': return 'Start preparing the order';
      case 'preparing': return 'Food is being made';
      case 'ready': return 'Ready for handoff';
      case 'delivered': return 'Order complete';
      case 'cancelled': return 'This order was cancelled';
      default: return '';
    }
  }

  Widget _sectionCard(String title, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.muted, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: bold ? AppColors.ink : AppColors.muted)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }

  Widget _actionRow(List<Widget> buttons) {
    return Row(children: [
      for (int i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(child: buttons[i]),
      ],
    ]);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onPressed, {bool outlined = false}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.white : color,
          foregroundColor: outlined ? color : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: outlined ? BorderSide(color: color) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
