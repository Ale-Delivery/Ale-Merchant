import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final List<Map<String, dynamic>> _promos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Promotions',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.orange),
              onPressed: _showCreateDialog)
        ],
      ),
      body: _promos.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.local_offer_rounded,
                      color: AppColors.orange, size: 32)),
              const SizedBox(height: 16),
              const Text('No promotions yet',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              const Text('Create your first promotion',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Promotion'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)))),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _promos.length,
              itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: Text(_promos[i]['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  )),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Coming Soon',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Promotion management requires a backend Promotions table. The UI is ready — once the backend is available, this screen will fully support creating, editing, pausing, and tracking merchant promotions.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }
}
