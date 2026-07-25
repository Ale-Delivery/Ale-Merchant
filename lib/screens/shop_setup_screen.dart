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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCategory = 'Burger';
  bool _isLoading = false;
  bool _editMode = false;

  final List<String> _categories = [
    'Burger',
    'Pizza',
    'Sandwich',
    'Coffee',
    'Bowl',
    'Sides',
    'Sri Lankan',
    'Chinese',
    'Italian',
    'Indian',
    'Dessert',
    'Seafood',
    'Mexican',
    'Thai',
    'Japanese',
    'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingShop();
  }

  Future<void> _loadExistingShop() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    try {
      final shop = await Supabase.instance.client
          .from('Restaurants')
          .select()
          .eq('owner_id', userId)
          .maybeSingle();
      if (shop != null && mounted) {
        setState(() {
          _editMode = true;
          _nameController.text = shop['name'] ?? '';
          _tagsController.text = shop['tags'] ?? '';
          _addressController.text = shop['address'] ?? '';
          _descriptionController.text = shop['description'] ?? '';
          _imageUrlController.text = shop['image_url'] ?? '';
          _phoneController.text = shop['phone'] ?? '';
          _emailController.text = shop['email'] ?? '';
          _selectedCategory = shop['category'] ?? 'Burger';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveShop() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter store name'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final shopId = 'rest-${DateTime.now().millisecondsSinceEpoch}';
      await Supabase.instance.client.from('Restaurants').upsert({
        'id': shopId,
        'name': _nameController.text.trim(),
        'image_url': _imageUrlController.text.trim().isEmpty
            ? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600'
            : _imageUrlController.text.trim(),
        'rating': 4.5,
        'category': _selectedCategory,
        'tags': _tagsController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'owner_id': userId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Store saved!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating));
        SellerNavigator.home(context, clearStack: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating));
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
    _phoneController.dispose();
    _emailController.dispose();
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
        title: Text(_editMode ? 'Store Settings' : 'Create Store',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard('Store Information', [
              SellerTextField(
                  label: 'Store Name',
                  controller: _nameController,
                  hint: 'e.g. Pizza Palace'),
              const SizedBox(height: 16),
              SellerTextField(
                  label: 'Store Image URL',
                  controller: _imageUrlController,
                  hint: 'https://...',
                  required: false),
              const SizedBox(height: 16),
              _buildDropdown('Cuisine', _selectedCategory, _categories,
                  (v) => setState(() => _selectedCategory = v!)),
              const SizedBox(height: 16),
              SellerTextField(
                  label: 'Tags',
                  controller: _tagsController,
                  hint: 'e.g. Pizza · Italian · Family',
                  required: false),
              const SizedBox(height: 16),
              SellerTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  hint: 'e.g. 077 123 4567',
                  keyboard: TextInputType.phone,
                  required: false),
              const SizedBox(height: 16),
              SellerTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  hint: 'e.g. store@example.com',
                  keyboard: TextInputType.emailAddress,
                  required: false),
              const SizedBox(height: 16),
              SellerTextField(
                  label: 'Business Address',
                  controller: _addressController,
                  hint: 'e.g. Colombo 03'),
              const SizedBox(height: 16),
              SellerTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  hint: 'Short description',
                  maxLines: 3,
                  required: false),
            ]),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => SellerNavigator.operations(context),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2))
                    ]),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.settings_rounded,
                          color: AppColors.orange, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Store Operations',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        const Text('Status, hours, preparation time & more',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                      ])),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.muted),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            SellerButton(
                label: _editMode ? 'Update Store' : 'Create Store',
                isLoading: _isLoading,
                onPressed: _saveShop),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 1)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14)),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                items: items
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: onChanged)),
      ),
    ]);
  }
}
