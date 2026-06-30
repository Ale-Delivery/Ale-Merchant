import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../navigation/seller_navigator.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {

  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Burger';
  String _deliveryFee = 'Free';
  String _deliveryTime = '25 min';
  int _deliveryMin = 25;
  bool _freeDelivery = true;
  bool _isOpen = true;
  bool _isLoading = false;
  bool _editMode = false;

  final List<String> _categories = ['Burger', 'Pizza', 'Sandwich', 'Coffee', 'Bowl', 'Sides', 'Sri Lankan', 'Chinese'];

  late final TextEditingController _deliveryFeeCtrl;
  late final TextEditingController _deliveryTimeCtrl;
  late final TextEditingController _deliveryMinCtrl;

  @override
  void initState() {
    super.initState();
    _deliveryFeeCtrl = TextEditingController(text: _deliveryFee);
    _deliveryTimeCtrl = TextEditingController(text: _deliveryTime);
    _deliveryMinCtrl = TextEditingController(text: '$_deliveryMin');
    _loadExistingShop();
  }

  Future<void> _loadExistingShop() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      final shop = await Supabase.instance.client.from('Restaurants').select().eq('owner_id', userId).maybeSingle();
      if (shop != null && mounted) {
        setState(() {
          _editMode = true;
          _nameController.text = shop['name'] ?? '';
          _tagsController.text = shop['tags'] ?? '';
          _addressController.text = shop['address'] ?? '';
          _descriptionController.text = shop['description'] ?? '';
          _imageUrlController.text = shop['image_url'] ?? '';
          _selectedCategory = shop['category'] ?? 'Burger';
          _deliveryFee = shop['delivery_fee']?.toString() ?? 'Free';
          _deliveryTime = shop['delivery_time']?.toString() ?? '25 min';
          _deliveryMin = shop['delivery_min'] ?? 25;
          _freeDelivery = shop['free_delivery'] ?? true;
          _isOpen = shop['is_open'] ?? true;
          _deliveryFeeCtrl.text = _deliveryFee;
          _deliveryTimeCtrl.text = _deliveryTime;
          _deliveryMinCtrl.text = '$_deliveryMin';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveShop() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter shop name'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final shopId = 'rest-${DateTime.now().millisecondsSinceEpoch}';

      final payload = {
        'id': shopId,
        'name': _nameController.text.trim(),
        'image_url': _imageUrlController.text.trim().isEmpty
            ? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600'
            : _imageUrlController.text.trim(),
        'rating': 4.5,
        'delivery_fee': _deliveryFee,
        'delivery_time': _deliveryTime,
        'delivery_min': _deliveryMin,
        'free_delivery': _freeDelivery,
        'is_open': _isOpen,
        'category': _selectedCategory,
        'tags': _tagsController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'owner_id': userId,
      };

      await Supabase.instance.client.from('Restaurants').upsert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Shop saved!'), backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating),
        );
        SellerNavigator.home(context, clearStack: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _deliveryFeeCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    _deliveryMinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Shop' : 'Create Shop', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Basic Info'),
            SellerTextField(label: 'Shop Name', controller: _nameController, hint: 'e.g. Pizza Palace'),
            const SizedBox(height: 16),
            SellerTextField(label: 'Image URL', controller: _imageUrlController, hint: 'e.g. https://images.unsplash.com/...', required: false),
            const SizedBox(height: 16),
            _buildDropdown('Category', _selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!)),
            const SizedBox(height: 16),
            SellerTextField(label: 'Tags', controller: _tagsController, hint: 'e.g. Pizza · Italian · Family', required: false),
            const SizedBox(height: 16),
            SellerTextField(label: 'Address', controller: _addressController, hint: 'e.g. Colombo 03'),
            const SizedBox(height: 16),
            SellerTextField(label: 'Description', controller: _descriptionController, hint: 'Short description of your restaurant', maxLines: 3, required: false),
            const SizedBox(height: 28),

            _sectionHeader('Delivery Settings'),
            Row(
              children: [
                Expanded(
                  child: SellerTextField(
                    label: 'Delivery Fee',
                    controller: _deliveryFeeCtrl,
                    hint: 'Free or Rs. 150',
                    onChanged: (v) => _deliveryFee = v.isEmpty ? 'Free' : v,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Delivery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.textHint, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _freeDelivery,
                        onChanged: (v) => setState(() => _freeDelivery = v),
                        title: Text(_freeDelivery ? 'Yes' : 'No', style: const TextStyle(fontWeight: FontWeight.w600)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SellerTextField(
                    label: 'Delivery Time',
                    controller: _deliveryTimeCtrl,
                    hint: 'e.g. 30 min',
                    onChanged: (v) => _deliveryTime = v,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SellerTextField(
                    label: 'Delivery Min',
                    controller: _deliveryMinCtrl,
                    hint: 'e.g. 25',
                    keyboard: TextInputType.number,
                    onChanged: (v) => _deliveryMin = int.tryParse(v) ?? _deliveryMin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _sectionHeader('Shop Status'),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shop Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.textHint, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _isOpen,
                        onChanged: (v) => setState(() => _isOpen = v),
                        title: Text(_isOpen ? 'Open for orders' : 'Temporarily closed', style: const TextStyle(fontWeight: FontWeight.w600)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SellerButton(
              label: _editMode ? 'Update Shop' : 'Create Shop',
              isLoading: _isLoading,
              onPressed: _saveShop,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.textHint, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(14)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary),
              items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
