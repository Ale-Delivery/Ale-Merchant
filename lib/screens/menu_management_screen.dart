import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      final shop = await Supabase.instance.client.from('Restaurants').select('id').eq('owner_id', userId).maybeSingle();
      if (shop != null) {
        _shopId = shop['id'];
        final items = await Supabase.instance.client.from('Menu_Items').select().eq('restaurant_id', _shopId!).order('created_at');
        if (mounted) setState(() { _items = List<Map<String, dynamic>>.from(items); _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    await Supabase.instance.client.from('Menu_Items').delete().eq('id', id);
    setState(() => _items.removeWhere((i) => i['id'] == id));
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final priceCtrl = TextEditingController(text: item?['price']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final imageCtrl = TextEditingController(text: item?['image_url'] ?? '');
    final categoryCtrl = TextEditingController(text: item?['category'] ?? '');
    String sizes = item?['sizes'] != null ? (item!['sizes'] as List).join(', ') : 'Regular';
    String ingredients = item?['ingredients'] != null ? (item!['ingredients'] as List).join(', ') : '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dlgField('Name *', nameCtrl),
              const SizedBox(height: 12),
              _dlgField('Price (Rs.) *', priceCtrl, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _dlgField('Category', categoryCtrl),
              const SizedBox(height: 12),
              _dlgField('Description', descCtrl, maxLines: 2),
              const SizedBox(height: 12),
              _dlgField('Image URL', imageCtrl),
              const SizedBox(height: 12),
              _dlgField('Sizes (comma separated)', TextEditingController(text: sizes), onSubmitted: (v) => sizes = v),
              const SizedBox(height: 12),
              _dlgField('Ingredients (comma separated)', TextEditingController(text: ingredients), onSubmitted: (v) => ingredients = v),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'name': nameCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                'category': categoryCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'image_url': imageCtrl.text.trim(),
                'sizes': sizes.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                'ingredients': ingredients.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && _shopId != null) {
      try {
        final payload = {
          'restaurant_id': _shopId,
          'name': result['name'],
          'price': result['price'],
          'category': result['category'],
          'description': result['description'],
          'image_url': result['image_url'],
          'rating': 4.5,
          'sizes': result['sizes'],
          'ingredients': result['ingredients'],
        };

        if (item != null) {
          payload['id'] = item['id'];
          await Supabase.instance.client.from('Menu_Items').upsert(payload);
        } else {
          payload['id'] = 'menu-${DateTime.now().millisecondsSinceEpoch}';
          await Supabase.instance.client.from('Menu_Items').insert(payload);
        }

        await _loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Item saved!'), backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
        }
      }
    }
  }

  Widget _dlgField(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType keyboard = TextInputType.text, ValueChanged<String>? onSubmitted}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Menu Items', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: _shopId != null ? FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ) : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _items.isEmpty
              ? EmptyState(
                  icon: Icons.restaurant_menu_rounded,
                  message: 'No menu items yet',
                  actionLabel: 'Add First Item',
                  onAction: () => _showAddEditDialog(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(item['image_url'] ?? ''), fit: BoxFit.cover)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Rs. ${item['price']}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, fontSize: 16)),
                            ]),
                          ),
                          IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.muted, size: 20), onPressed: () => _showAddEditDialog(item: item)),
                          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20), onPressed: () => _deleteItem(item['id'])),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
