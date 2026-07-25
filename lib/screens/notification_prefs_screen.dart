import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  bool _newOrder = true,
      _cancellation = true,
      _lowStock = true,
      _newReview = true,
      _paymentReceived = true,
      _payoutCompleted = true,
      _staffActivity = false,
      _promoExpiry = true;
  bool _pushEnabled = true, _soundEnabled = true, _vibrateEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Notification Settings',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _section('Channels', [
              _toggle('Push Notifications', 'Receive push notifications',
                  _pushEnabled, (v) => setState(() => _pushEnabled = v)),
              _toggle('Sound', 'Play sound for notifications', _soundEnabled,
                  (v) => setState(() => _soundEnabled = v)),
              _toggle('Vibration', 'Vibrate on notifications', _vibrateEnabled,
                  (v) => setState(() => _vibrateEnabled = v)),
            ]),
            const SizedBox(height: 16),
            _section('Events', [
              _toggle('New Orders', 'When a new order is placed', _newOrder,
                  (v) => setState(() => _newOrder = v)),
              _toggle('Order Cancellations', 'When an order is cancelled',
                  _cancellation, (v) => setState(() => _cancellation = v)),
              _toggle('Low Stock Alerts', 'When stock runs low', _lowStock,
                  (v) => setState(() => _lowStock = v)),
              _toggle('New Reviews', 'When a customer reviews', _newReview,
                  (v) => setState(() => _newReview = v)),
              _toggle(
                  'Payment Received',
                  'When a payment is confirmed',
                  _paymentReceived,
                  (v) => setState(() => _paymentReceived = v)),
              _toggle(
                  'Payout Completed',
                  'When a payout is processed',
                  _payoutCompleted,
                  (v) => setState(() => _payoutCompleted = v)),
              _toggle('Staff Activity', 'Staff login/logout activity',
                  _staffActivity, (v) => setState(() => _staffActivity = v)),
              _toggle('Promotion Expiry', 'When promotions are expiring',
                  _promoExpiry, (v) => setState(() => _promoExpiry = v)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFE65100), size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Push notification delivery requires a backend notification infrastructure. Settings are saved locally.',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFE65100)))),
              ]),
            ),
          ]),
    );
  }

  Widget _section(String title, List<Widget> children) {
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
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Widget _toggle(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
        Switch(
            value: value, activeColor: AppColors.green, onChanged: onChanged),
      ]),
    );
  }
}
