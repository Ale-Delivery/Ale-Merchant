import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final List<Map<String, dynamic>> _staff = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Staff',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _staff.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.people_rounded,
                      color: AppColors.orange, size: 32)),
              const SizedBox(height: 16),
              const Text('No staff accounts',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              const Text('Staff management requires a merchant_staff table',
                  style: TextStyle(color: AppColors.muted)),
            ]))
          : ListView.builder(
              itemCount: _staff.length,
              itemBuilder: (_, i) => const SizedBox.shrink()),
    );
  }
}
