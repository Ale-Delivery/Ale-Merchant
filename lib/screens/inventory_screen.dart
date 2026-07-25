import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  bool _gridView = false;
  String _searchQuery = '';
  String _stockFilter = 'All';
  String _sortBy = 'name';
  String? _shopId;
  final _searchCtrl = TextEditingController();

  static const _sortOptions = {
    'name': 'Name',
    'newest': 'Newest',
    'oldest': 'Oldest',
    'stock_high': 'Highest Stock',
    'stock_low': 'Lowest Stock',
  };

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _searchQuery = _searchCtrl.text.toLowerCase();
      _apply();
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _lowStockCount =>
      _items.where((i) => _stockStatus(i) == 'low').length;
  int get _outOfStockCount =>
      _items.where((i) => _stockStatus(i) == 'out').length;

  String _stockStatus(Map<String, dynamic> item) {
    final stock = (item['stock'] as num?)?.toInt();
    if (stock == null || stock < 0) return 'unlimited';
    if (stock == 0) return 'out';
    final threshold = (item['low_stock_threshold'] as num?)?.toInt() ?? 10;
    if (stock <= threshold) return 'low';
    return 'in';
  }

  String _stockLabel(Map<String, dynamic> item) {
    final stock = (item['stock'] as num?)?.toInt();
    switch (_stockStatus(item)) {
      case 'unlimited':
        return 'Unlimited';
      case 'out':
        return 'Out of Stock';
      case 'low':
        return 'Low Stock ($stock)';
      default:
        return 'In Stock (${stock ?? 0})';
    }
  }

  Color _stockColor(String status) {
    switch (status) {
      case 'unlimited':
        return AppColors.green;
      case 'out':
        return AppColors.red;
      case 'low':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.green;
    }
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final String userId = user.id;
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
            .order('name');
        if (mounted)
          setState(() {
            _items = List<Map<String, dynamic>>.from(items);
            _loading = false;
            _apply();
          });
      } else if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply() {
    final filtered = _items.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final cat = (item['category'] ?? '').toString();
      final status = _stockStatus(item);
      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          cat.toLowerCase().contains(_searchQuery);
      final matchesFilter = _stockFilter == 'All' || status == _stockFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => (b['created_at'] ?? '')
            .toString()
            .compareTo((a['created_at'] ?? '').toString()));
      case 'oldest':
        filtered.sort((a, b) => (a['created_at'] ?? '')
            .toString()
            .compareTo((b['created_at'] ?? '').toString()));
      case 'stock_high':
        filtered.sort((a, b) => ((b['stock'] as num?)?.toInt() ?? 0)
            .compareTo((a['stock'] as num?)?.toInt() ?? 0));
      case 'stock_low':
        filtered.sort((a, b) => ((a['stock'] as num?)?.toInt() ?? 0)
            .compareTo((b['stock'] as num?)?.toInt() ?? 0));
      default:
        filtered.sort((a, b) => (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString()));
    }

    setState(() => _filtered = filtered);
  }

  Future<void> _updateStock(String id, int stock) async {
    await Supabase.instance.client
        .from('Menu_Items')
        .update({'stock': stock.clamp(0, 999999)}).eq('id', id);
    final idx = _items.indexWhere((i) => i['id'] == id);
    if (idx >= 0) _items[idx]['stock'] = stock.clamp(0, 999999);
    _apply();
  }

  Future<void> _updateThreshold(String id, int threshold) async {
    await Supabase.instance.client
        .from('Menu_Items')
        .update({'low_stock_threshold': threshold}).eq('id', id);
    final idx = _items.indexWhere((i) => i['id'] == id);
    if (idx >= 0) _items[idx]['low_stock_threshold'] = threshold;
    _apply();
  }

  void _showActions(Map<String, dynamic> item) {
    final id = item['id'];
    final current = (item['stock'] as num?)?.toInt();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(item['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                    'Current stock: ${current != null && current >= 0 ? current.toString() : 'Unlimited'}',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 16),
                _actionBtn(Icons.add_circle_outline, 'Increase Stock',
                    () => _showQtyDialog(id, 'Increase', 1)),
                _actionBtn(Icons.remove_circle_outline, 'Decrease Stock',
                    () => _showQtyDialog(id, 'Decrease', -1)),
                _actionBtn(Icons.edit_rounded, 'Set Exact Quantity',
                    () => _showSetDialog(id, current)),
                if (current == null || current < 0 || current > 0)
                  _actionBtn(Icons.block_rounded, 'Mark Out of Stock',
                      () async {
                    await _updateStock(id, 0);
                    Navigator.pop(ctx);
                  }),
                if (current != null && current >= 0)
                  _actionBtn(Icons.all_inclusive, 'Mark Unlimited', () async {
                    await _updateStock(id, -1);
                    Navigator.pop(ctx);
                  }),
                _actionBtn(Icons.tune_rounded, 'Edit Low-Stock Threshold',
                    () => _showThresholdDialog(id, item)),
                _actionBtn(Icons.history_rounded, 'View Stock History',
                    () => _showHistory(item)),
              ]),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.orange),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showQtyDialog(String id, String action, int multiplier) {
    final ctrl = TextEditingController(text: '1');
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('$action Stock',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Quantity', border: OutlineInputBorder())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      final qty = int.tryParse(ctrl.text);
                      if (qty != null && qty > 0) Navigator.pop(ctx, qty);
                    },
                    child: const Text('Confirm')),
              ],
            )).then((qty) async {
      if (qty != null) {
        final current =
            _items.firstWhere((i) => i['id'] == id)['stock'] as num?;
        final base = (current ?? 0) as int;
        final newVal = base + (qty as int) * multiplier;
        if (newVal >= 0) await _updateStock(id, newVal);
      }
    });
  }

  void _showSetDialog(String id, int? current) {
    final ctrl = TextEditingController(
        text: current != null && current >= 0 ? current.toString() : '0');
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Set Stock',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'New quantity', border: OutlineInputBorder())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text);
                      if (v != null && v >= 0) Navigator.pop(ctx, v);
                    },
                    child: const Text('Save')),
              ],
            )).then((v) async {
      if (v != null) await _updateStock(id, v as int);
    });
  }

  void _showThresholdDialog(String id, Map<String, dynamic> item) {
    final current = (item['low_stock_threshold'] as num?)?.toInt() ?? 10;
    final ctrl = TextEditingController(text: current.toString());
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Low-Stock Threshold',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Alert when stock is at or below',
                      border: OutlineInputBorder())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text);
                      if (v != null && v >= 0) Navigator.pop(ctx, v);
                    },
                    child: const Text('Save')),
              ],
            )).then((v) async {
      if (v != null) await _updateThreshold(id, v as int);
    });
  }

  void _showHistory(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock History: ${item['name']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFE65100), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            'Stock history tracking requires a stock_history table. Current stock: ${item['stock'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFE65100)))),
                  ]),
                ),
                const SizedBox(height: 16),
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close')),
              ]),
        ),
      ),
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
        title: const Text('Inventory',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.orange),
            onSelected: (v) {
              _sortBy = v;
              _apply();
            },
            itemBuilder: (_) => _sortOptions.entries
                .map((e) => PopupMenuItem(
                    value: e.key,
                    child: Text(_sortBy == e.key ? '✓ ${e.value}' : e.value)))
                .toList(),
          ),
          IconButton(
              icon: Icon(
                  _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: AppColors.orange),
              onPressed: () => setState(() => _gridView = !_gridView)),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2.5))
          : Column(children: [
              if (_lowStockCount > 0 || _outOfStockCount > 0)
                GestureDetector(
                  onTap: () {
                    _stockFilter = 'low';
                    _apply();
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFE65100), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            '${_lowStockCount > 0 ? '$_lowStockCount low stock' : ''}${_lowStockCount > 0 && _outOfStockCount > 0 ? ' · ' : ''}${_outOfStockCount > 0 ? '$_outOfStockCount out of stock' : ''}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE65100))),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFE65100), size: 18),
                    ]),
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or category...',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: AppColors.muted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                size: 18, color: AppColors.muted),
                            onPressed: () {
                              _searchCtrl.clear();
                            })
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _filterChip('All', 'All'),
                      _filterChip('In Stock', 'in'),
                      _filterChip('Low Stock', 'low'),
                      _filterChip('Out of Stock', 'out'),
                      _filterChip('Unlimited', 'unlimited'),
                    ]),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.inventory_2_rounded,
                            size: 56, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text('No items found',
                            style: TextStyle(color: AppColors.muted)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _gridView
                            ? GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.85,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildGridCard(_filtered[i]))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildListCard(_filtered[i])),
                      ),
              ),
            ]),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _stockFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _stockFilter = value;
          _apply();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: selected ? AppColors.orange : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87)),
        ),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    final status = _stockStatus(item);
    final color = _stockColor(status);
    final image = item['image_url'] ?? '';
    return GestureDetector(
      onTap: () => _showActions(item),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
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
                          color: AppColors.muted, size: 40)),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: color)),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(_stockLabel(item),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showActions(item),
                      child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Center(
                              child: Text('Manage',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.orange)))),
                    ),
                  ])),
        ]),
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> item) {
    final status = _stockStatus(item);
    final color = _stockColor(status);
    final image = item['image_url'] ?? '';
    return GestureDetector(
      onTap: () => _showActions(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1))
            ]),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12)),
              child: image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.fastfood_rounded,
                              color: AppColors.muted,
                              size: 24)))
                  : const Icon(Icons.fastfood_rounded,
                      color: AppColors.muted, size: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 4),
                  Text(_stockLabel(item),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              ])),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.muted),
        ]),
      ),
    );
  }
}
