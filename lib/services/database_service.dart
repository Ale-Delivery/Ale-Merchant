import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Restaurant>> getRestaurants() async {
    final response = await _client.from('Restaurants').select();
    return (response as List)
        .map((r) => Restaurant.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  static Future<List<FoodItem>> getFoodItems({required String restaurantId}) =>
      getMenuItems(restaurantId);

  static Future<List<FoodItem>> getMenuItems(String restaurantId) async {
    final response = await _client
        .from('Menu_Items')
        .select()
        .eq('restaurant_id', restaurantId);

    return (response as List)
        .map(
          (item) => foodItemFromMenuRow(
            Map<String, dynamic>.from(item),
            restaurantId: restaurantId,
          ),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return {'restaurants': <Restaurant>[], 'foods': <FoodItem>[]};
    }

    final restaurants = await getRestaurants();
    final matchedRestaurants = restaurants
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.category.toLowerCase().contains(q),
        )
        .toList();

    final foods = <FoodItem>[];
    for (final restaurant in restaurants) {
      final items = await getMenuItems(restaurant.id);
      foods.addAll(
        items.where(
          (f) =>
              f.name.toLowerCase().contains(q) ||
              f.category.toLowerCase().contains(q) ||
              f.restaurantName.toLowerCase().contains(q),
        ),
      );
    }

    return {'restaurants': matchedRestaurants, 'foods': foods};
  }

  static FoodItem foodItemFromMenuRow(
    Map<String, dynamic> item, {
    required String restaurantId,
    String restaurantName = '',
    bool freeDelivery = true,
    int deliveryMin = 25,
  }) {
    return FoodItem(
      id: item['id']?.toString() ?? '',
      name: item['name'] ?? '',
      imageUrl: item['image_url'] ?? '',
      price: _toDouble(item['price']),
      rating: _toDouble(item['rating'], fallback: 4.5),
      freeDelivery: freeDelivery,
      deliveryMin: deliveryMin,
      restaurantName: restaurantName.isNotEmpty
          ? restaurantName
          : (item['restaurant_name'] ?? ''),
      restaurantId: restaurantId,
      category: item['category'] ?? '',
      description: item['description'] ?? '',
      sizes: List<String>.from(item['sizes'] ?? ['Regular']),
      ingredients: List<String>.from(item['ingredients'] ?? []),
    );
  }

  static FoodItem foodItemFromMenuAndRestaurant(
    Map<String, dynamic> item,
    Map<String, dynamic> restaurant,
  ) {
    final fee = restaurant['delivery_fee']?.toString() ?? 'Free';
    return foodItemFromMenuRow(
      item,
      restaurantId: restaurant['id']?.toString() ?? '',
      restaurantName: restaurant['name'] ?? '',
      freeDelivery: fee.toLowerCase() == 'free',
      deliveryMin: _parseDeliveryMin(restaurant),
    );
  }

  static int _parseDeliveryMin(Map<String, dynamic> restaurant) {
    final raw =
        (restaurant['delivery_time'] ?? restaurant['delivery_min'] ?? '25')
            .toString();
    final digits = RegExp(r'\d+').firstMatch(raw);
    return digits != null ? int.parse(digits.group(0)!) : 25;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }
}
