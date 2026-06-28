import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _primary = Color(0xFFFF6B35);
  static const _ink = Color(0xFF1E1E2C);
  static const _muted = Color(0xFF7D8491);

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
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF3B82F6);
      case 'preparing':
        return const Color(0xFF8B5CF6);
      case 'ready':
        return const Color(0xFF10B981);
      case 'delivered':
        return const Color(0xFF6B7280);
      default:
        return _muted;
    }
  }

  String _statusLabel(String status) =>
      status[0].toUpperCase() + status.substring(1);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Detail', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _muted, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final status = order['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Order #${order['id']?.toString().substring(0, 8) ?? ''}',
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _statusColor(status).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: _statusColor(status), size: 10),
                const SizedBox(width: 10),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Order info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 14),
                _infoRow(Icons.location_on_outlined, 'Delivery Address', order['delivery_address'] ?? 'N/A'),
                const SizedBox(height: 10),
                _infoRow(Icons.phone_outlined, 'Phone', order['delivery_phone'] ?? 'N/A'),
                const SizedBox(height: 10),
                _infoRow(Icons.payment_outlined, 'Payment', (order['payment_method'] ?? 'cash') == 'cash' ? 'Cash on Delivery' : (order['payment_method'] ?? 'Cash')),
                if (order['delivery_notes'] != null && order['delivery_notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoRow(Icons.note_outlined, 'Notes', order['delivery_notes'].toString()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items (${_items.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 14),
                ..._items.map((item) {
                  final name = item['name'] ?? '';
                  final qty = item['quantity'] ?? 0;
                  final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
                  final size = item['selected_size']?.toString();
                  final image = item['image_url']?.toString() ?? '';
                  final lineTotal = price * (qty is int ? qty : (qty as num).toInt());

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF3F4F6),
                            image: image.isNotEmpty
                                ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                                : null,
                          ),
                          child: image.isEmpty
                              ? const Icon(Icons.fastfood, color: _muted, size: 24)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
                              const SizedBox(height: 2),
                              Text(
                                '${size != null ? '$size x ' : ''}${qty}x  •  Rs. ${lineTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: _muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs. ${price.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                // Price breakdown
                _priceRow('Subtotal', 'Rs. ${(order['subtotal'] ?? 0)}'),
                const SizedBox(height: 8),
                _priceRow('Delivery Fee', 'Rs. ${(order['delivery_fee'] ?? 0)}'),
                const SizedBox(height: 8),
                const Divider(height: 0, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 8),
                _priceRow('Total', 'Rs. ${(order['total'] ?? 0)}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'Accept Order',
                    Icons.check_circle_outline,
                    const Color(0xFF10B981),
                    () => _updateStatus('accepted'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    'Reject',
                    Icons.cancel_outlined,
                    const Color(0xFFEF4444),
                    () => _updateStatus('cancelled'),
                  ),
                ),
              ],
            )
          else if (status == 'accepted')
            _actionButton(
              'Start Preparing',
              Icons.restaurant_rounded,
              const Color(0xFF8B5CF6),
              () => _updateStatus('preparing'),
            )
          else if (status == 'preparing')
            _actionButton(
              'Mark Ready',
              Icons.check_circle_outline,
              const Color(0xFF10B981),
              () => _updateStatus('ready'),
            )
          else if (status == 'ready')
            _actionButton(
              'Mark Delivered',
              Icons.delivery_dining,
              const Color(0xFF6B7280),
              () => _updateStatus('delivered'),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: bold ? _ink : _muted)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: _ink)),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
