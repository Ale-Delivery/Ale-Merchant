import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _selectedCategory;
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _categories = [
    'Account Issue',
    'Store Settings',
    'Order Dispute',
    'Payment Issue',
    'Technical Problem',
    'Feature Request',
    'Other'
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Support',
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
            _card('Help Center', Icons.help_center_rounded, [
              ListTile(
                  title: const Text('Frequently Asked Questions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _comingSoon()),
              ListTile(
                  title: const Text('Contact Support'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _comingSoon()),
              ListTile(
                  title: const Text('Report a Problem'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _comingSoon()),
            ]),
            const SizedBox(height: 16),
            _card('Submit a Ticket', Icons.support_agent_rounded, [
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
              const SizedBox(height: 12),
              TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Ticket submission requires a backend support_tickets table. Your request has been noted.'),
                          behavior: SnackBarBehavior.floating),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Submit Ticket',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
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
        Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.orange, size: 18)),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87))
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This feature requires backend integration'),
        behavior: SnackBarBehavior.floating));
  }
}
