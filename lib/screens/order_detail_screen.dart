import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

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
        if (mounted) {
          setState(() {
            _error = 'Order not found';
            _loading = false;
          });
        }
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
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _updateStatus(String status) async {
    await Supabase.instance.client
        .from('Orders')
        .update({'status': status}).eq('id', widget.orderId);
    setState(() => _order!['status'] = status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${_statusLabel(status).toLowerCase()}'),
          backgroundColor:
              status == 'cancelled' ? AppColors.red : AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _order != null
              ? '#${_order!['id'].toString().substring(0, 8)}'
              : 'Order Details',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 14),
                      _buildTimeline(),
                      const SizedBox(height: 14),
                      _buildItemsCard(),
                      const SizedBox(height: 14),
                      _buildSummaryCard(),
                      const SizedBox(height: 14),
                      _buildDeliveryCard(),
                      const SizedBox(height: 14),
                      _buildActions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {
                _loading = true;
                _error = null;
                _loadOrder();
              }),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final order = _order!;
    final status = order['status'] ?? 'pending';
    final color = _statusColor(status);
    final dateStr = order['created_at'] != null
        ? DateFormat('MMM d, yyyy  h:mm a')
            .format(DateTime.parse(order['created_at']))
        : '';

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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_statusIcon(status), color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusSubtitle(status),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final order = _order!;
    final status = order['status'] ?? 'pending';

    if (status == 'cancelled') {
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
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Cancelled',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red)),
                  Text('This order was cancelled by the merchant.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final steps = _buildSteps();
    final currentStep = _stepIndex(status);

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
          const Text('Order Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final done = i <= currentStep;
            final active = i == currentStep;
            final isLast = i == steps.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              done ? AppColors.orange : const Color(0xFFE0E0E0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          done ? Icons.check : Icons.circle_outlined,
                          size: 16,
                          color: done ? Colors.white : AppColors.muted,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: done
                                ? AppColors.orange
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: active ? AppColors.orange : Colors.black87,
                            ),
                          ),
                          Text(
                            steps[i].subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
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
          Text('Order Items (${_items.length})',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ..._items.map((item) {
            final name = item['name'] ?? '';
            final qty = item['quantity'] ?? 0;
            final price = (item['price'] is num)
                ? (item['price'] as num).toDouble()
                : 0.0;
            final size = item['selected_size']?.toString();
            final image = item['image_url']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.fastfood_rounded,
                                    color: AppColors.muted,
                                    size: 24)),
                          )
                        : Icon(Icons.fastfood_rounded,
                            color: AppColors.muted, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${size != null ? '$size · ' : ''}${qty}x @ Rs. ${price.toStringAsFixed(0)}',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${(price * qty).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.orange),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final order = _order!;
    final subtotal = (order['subtotal'] is num)
        ? (order['subtotal'] as num).toDouble()
        : 0.0;
    final deliveryFee = (order['delivery_fee'] is num)
        ? (order['delivery_fee'] as num).toDouble()
        : 0.0;
    final total =
        (order['total'] is num) ? (order['total'] as num).toDouble() : 0.0;

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
          const Text('Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _priceRow('Subtotal', 'Rs. ${subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _priceRow(
              'Delivery Fee',
              deliveryFee == 0
                  ? 'Free'
                  : 'Rs. ${deliveryFee.toStringAsFixed(0)}'),
          const Divider(height: 24),
          _priceRow('Total', 'Rs. ${total.toStringAsFixed(0)}',
              bold: true, total: true),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    final order = _order!;
    final method = order['payment_method'] ?? 'cash';
    final methodLabel =
        method == 'cash' ? 'Cash on Delivery' : method.toString();

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
          const Text('Delivery Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _infoRow(Icons.location_on_outlined, 'Address',
              order['delivery_address'] ?? 'N/A'),
          if (order['delivery_phone'] != null &&
              order['delivery_phone'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _infoRow(
                  Icons.phone_outlined, 'Phone', order['delivery_phone']),
            ),
          if (order['delivery_notes'] != null &&
              order['delivery_notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _infoRow(
                  Icons.note_outlined, 'Notes', order['delivery_notes']),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _infoRow(Icons.payments_outlined, 'Payment', methodLabel),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final order = _order!;
    final status = order['status'] ?? 'pending';

    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('accepted'),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Accept',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('cancelled'),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text('Reject',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus('preparing'),
          icon: const Icon(Icons.restaurant_rounded, size: 20),
          label: const Text('Start Preparing',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    if (status == 'preparing') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus('ready'),
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: const Text('Mark Ready',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    if (status == 'ready') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus('delivered'),
          icon: const Icon(Icons.delivery_dining, size: 20),
          label: const Text('Mark Delivered',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.muted, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value,
      {bool bold = false, bool total = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: total ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: total ? Colors.black87 : AppColors.muted,
            )),
        Text(value,
            style: TextStyle(
              fontSize: total ? 20 : 14,
              fontWeight: FontWeight.w800,
              color: total ? AppColors.orange : Colors.black87,
            )),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
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

  String _statusSubtitle(String status) {
    switch (status) {
      case 'pending':
        return 'Awaiting your response';
      case 'accepted':
        return 'Start preparing the order';
      case 'preparing':
        return 'Food is being prepared';
      case 'ready':
        return 'Ready for pickup';
      case 'delivered':
        return 'Order completed successfully';
      case 'cancelled':
        return 'This order was cancelled';
      default:
        return '';
    }
  }

  int _stepIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'preparing':
        return 2;
      case 'ready':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  List<_TimelineStep> _buildSteps() {
    return [
      _TimelineStep('Placed', 'Order has been placed'),
      _TimelineStep('Confirmed', 'Order accepted'),
      _TimelineStep('Preparing', 'Food being prepared'),
      _TimelineStep('Ready', 'Ready for pickup'),
      _TimelineStep('Delivered', 'Order completed'),
    ];
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  const _TimelineStep(this.title, this.subtitle);
}
