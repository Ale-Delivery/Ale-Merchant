import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class MenuManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const MenuManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _shopId;
  bool _gridView = true;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
      _applyFilter();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Set<String> get _categories {
    final cats =
        _items.map((i) => i['category']?.toString() ?? 'Other').toSet();
    return {'All', ...cats};
  }

  void _applyFilter() {
    setState(() {
      _filtered = _items.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final cat = (item['category'] ?? '').toString();
        final matchesSearch =
            _searchQuery.isEmpty || name.contains(_searchQuery);
        final matchesCategory =
            _selectedCategory == 'All' || cat == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _loadItems() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop != null) {
        _shopId = shop['id'];
        final items = await Supabase.instance.client
            .from('Menu_Items')
            .select()
            .eq('restaurant_id', _shopId!)
            .order('created_at');
        if (mounted) {
          setState(() {
            _items = List<Map<String, dynamic>>.from(items);
            _loading = false;
          });
          _applyFilter();
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete item?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    await Supabase.instance.client.from('Menu_Items').delete().eq('id', id);
    setState(() => _items.removeWhere((i) => i['id'] == id));
    _applyFilter();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Item deleted'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _toggleActive(String id, bool isAvailable) async {
    await Supabase.instance.client
        .from('Menu_Items')
        .update({'is_available': !isAvailable}).eq('id', id);
    final idx = _items.indexWhere((i) => i['id'] == id);
    if (idx >= 0) _items[idx]['is_available'] = !isAvailable;
    _applyFilter();
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final priceCtrl =
        TextEditingController(text: item?['price']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final imageCtrl = TextEditingController(text: item?['image_url'] ?? '');
    String category = item?['category'] ?? '';
    String sizes = item?['sizes'] != null
        ? (item!['sizes'] as List).join(', ')
        : 'Regular';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item == null ? 'Add Product' : 'Edit Product',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                _field('Product Name *', nameCtrl),
                const SizedBox(height: 14),
                _field('Price (Rs.) *', priceCtrl,
                    keyboard: TextInputType.number),
                const SizedBox(height: 14),
                _field('Category', TextEditingController(text: category),
                    onChanged: (v) => category = v),
                const SizedBox(height: 14),
                _field('Description', descCtrl, maxLines: 2),
                const SizedBox(height: 14),
                _field('Image URL', imageCtrl),
                const SizedBox(height: 14),
                _field('Sizes (comma separated)',
                    TextEditingController(text: sizes),
                    onChanged: (v) => sizes = v),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty ||
                              priceCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx, {
                            'name': nameCtrl.text.trim(),
                            'price':
                                double.tryParse(priceCtrl.text.trim()) ?? 0,
                            'category': category,
                            'description': descCtrl.text.trim(),
                            'image_url': imageCtrl.text.trim(),
                            'sizes': sizes
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList(),
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Product saved!'),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating));
        }
      }
    }
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1,
      TextInputType keyboard = TextInputType.text,
      ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Products',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: context.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          IconButton(
            icon: Icon(
                _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: AppColors.orange),
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
        ],
      ),
      floatingActionButton: _shopId != null
          ? FloatingActionButton(
              onPressed: () => _showAddEditDialog(),
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: TextStyle(color: AppColors.muted),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: AppColors.muted, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        color: AppColors.muted, size: 18),
                                    onPressed: () => _searchCtrl.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _categories.map((cat) {
                            final selected = cat == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCategory = cat);
                                  _applyFilter();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.orange
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restaurant_menu_rounded,
                                  size: 56, color: AppColors.muted),
                              const SizedBox(height: 12),
                              Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No products found'
                                      : 'No products yet',
                                  style: TextStyle(
                                      fontSize: 16, color: AppColors.muted)),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddEditDialog(),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Product'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadItems,
                          child: _gridView
                              ? GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) =>
                                      _buildGridCard(_filtered[i]),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) =>
                                      _buildListCard(_filtered[i]),
                                ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    final name = item['name'] ?? '';
    final price = item['price'] ?? 0;
    final image = item['image_url'] ?? '';
    final isAvailable = item['is_available'] ?? true;
    final cat = item['category'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF3F4F6),
                    child: image.isNotEmpty
                        ? Image.network(image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.fastfood_rounded,
                                color: AppColors.muted,
                                size: 40))
                        : const Icon(Icons.fastfood_rounded,
                            color: AppColors.muted, size: 40),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleActive(item['id'], isAvailable),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4)
                        ],
                      ),
                      child: Icon(
                        isAvailable
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 16,
                        color: isAvailable ? AppColors.green : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (cat.isNotEmpty)
                  Text(cat,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.muted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text('Rs. $price',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange)),
                    ),
                    _gridAction(Icons.edit_rounded,
                        () => _showAddEditDialog(item: item)),
                    const SizedBox(width: 4),
                    _gridAction(Icons.delete_outline_rounded,
                        () => _deleteItem(item['id']),
                        isDestructive: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridAction(IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.red.withValues(alpha: 0.06)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 14, color: isDestructive ? AppColors.red : AppColors.muted),
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> item) {
    final name = item['name'] ?? '';
    final price = item['price'] ?? 0;
    final image = item['image_url'] ?? '';
    final isAvailable = item['is_available'] ?? true;
    final cat = item['category'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.fastfood_rounded,
                            color: AppColors.muted,
                            size: 28)),
                  )
                : const Icon(Icons.fastfood_rounded,
                    color: AppColors.muted, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (cat.isNotEmpty)
                  Text(cat,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                Text('Rs. $price',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange)),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            activeColor: AppColors.orange,
            onChanged: (_) => _toggleActive(item['id'], isAvailable),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: AppColors.muted),
            onPressed: () => _showAddEditDialog(item: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.red),
            onPressed: () => _deleteItem(item['id']),
          ),
        ],
      ),
    );
  }
}
