// ─── Restaurant Model ──────────────────────────────────────────
class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final bool freeDelivery;
  final int deliveryMin;
  final String category;
  final String description;
  final String address;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.freeDelivery,
    required this.deliveryMin,
    required this.category,
    required this.description,
    required this.address,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        imageUrl: json['image_url'] ?? '',
        rating: _toDouble(json['rating']),
        freeDelivery: json['free_delivery'] ?? true,
        deliveryMin: _toInt(json['delivery_min'], fallback: 20),
        category: json['category'] ?? '',
        description: json['description'] ?? '',
        address: json['address'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'rating': rating,
        'free_delivery': freeDelivery,
        'delivery_min': deliveryMin,
        'category': category,
        'description': description,
        'address': address,
      };
}

// ─── Food Item Model ───────────────────────────────────────────
class FoodItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double rating;
  final bool freeDelivery;
  final int deliveryMin;
  final String restaurantName;
  final String restaurantId;
  final String category;
  final String description;
  final List<String> sizes;
  final List<String> ingredients;

  const FoodItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.freeDelivery,
    required this.deliveryMin,
    required this.restaurantName,
    required this.restaurantId,
    required this.category,
    required this.description,
    required this.sizes,
    required this.ingredients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        imageUrl: json['image_url'] ?? '',
        price: _toDouble(json['price']),
        rating: _toDouble(json['rating']),
        freeDelivery: json['free_delivery'] ?? true,
        deliveryMin: _toInt(json['delivery_min'], fallback: 20),
        restaurantName: json['restaurant_name'] ?? '',
        restaurantId: json['restaurant_id']?.toString() ?? '',
        category: json['category'] ?? '',
        description: json['description'] ?? '',
        sizes: List<String>.from(json['sizes'] ?? ['10"', '14"', '16"']),
        ingredients: List<String>.from(json['ingredients'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'price': price,
        'rating': rating,
        'free_delivery': freeDelivery,
        'delivery_min': deliveryMin,
        'restaurant_name': restaurantName,
        'restaurant_id': restaurantId,
        'category': category,
        'description': description,
        'sizes': sizes,
        'ingredients': ingredients,
      };
}

// ─── Category Model ────────────────────────────────────────────
class FoodCategory {
  final String id;
  final String name;
  final String emoji;
  final bool isSelected;

  const FoodCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.isSelected = false,
  });

  FoodCategory copyWith({bool? isSelected}) => FoodCategory(
        id: id,
        name: name,
        emoji: emoji,
        isSelected: isSelected ?? this.isSelected,
      );
}

// ─── Cart Item Model ───────────────────────────────────────────
class CartItem {
  final FoodItem food;
  int quantity;
  String selectedSize;

  CartItem({
    required this.food,
    this.quantity = 1,
    this.selectedSize = '10"',
  });

  double get total => food.price * quantity;
}

// ─── Order Status ──────────────────────────────────────────────
enum OrderStatus {
  pending('pending'),
  accepted('accepted'),
  preparing('preparing'),
  ready('ready'),
  onTheWay('on_the_way'),
  delivered('delivered'),
  cancelled('cancelled');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String? raw) {
    return OrderStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Waiting for restaurant';
      case OrderStatus.accepted:
        return 'Order accepted';
      case OrderStatus.preparing:
        return 'Preparing your food';
      case OrderStatus.ready:
        return 'Ready for pickup';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.onTheWay:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

// ─── Order Model ───────────────────────────────────────────────
class Order {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String deliveryPhone;
  final String? deliveryNotes;
  final String paymentMethod;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    required this.deliveryPhone,
    this.deliveryNotes,
    this.paymentMethod = 'cash',
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        restaurantId: json['restaurant_id']?.toString() ?? '',
        restaurantName: json['restaurant_name'] ?? '',
        status: OrderStatus.fromString(json['status']?.toString()),
        subtotal: _toDouble(json['subtotal']),
        deliveryFee: _toDouble(json['delivery_fee']),
        total: _toDouble(json['total']),
        deliveryAddress: json['delivery_address'] ?? '',
        deliveryPhone: json['delivery_phone'] ?? '',
        deliveryNotes: json['delivery_notes']?.toString(),
        paymentMethod: json['payment_method'] ?? 'cash',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'status': status.value,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'delivery_address': deliveryAddress,
        'delivery_phone': deliveryPhone,
        'delivery_notes': deliveryNotes,
        'payment_method': paymentMethod,
        'created_at': createdAt?.toIso8601String(),
      };
}

// ─── Order Item Line ───────────────────────────────────────────
class OrderItemLine {
  final String id;
  final String orderId;
  final String? foodItemId;
  final String name;
  final double price;
  final int quantity;
  final String? selectedSize;
  final String? imageUrl;

  const OrderItemLine({
    required this.id,
    required this.orderId,
    this.foodItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.selectedSize,
    this.imageUrl,
  });

  double get lineTotal => price * quantity;

  factory OrderItemLine.fromJson(Map<String, dynamic> json) => OrderItemLine(
        id: json['id']?.toString() ?? '',
        orderId: json['order_id']?.toString() ?? '',
        foodItemId: json['food_item_id']?.toString(),
        name: json['name'] ?? '',
        price: _toDouble(json['price']),
        quantity: _toInt(json['quantity'], fallback: 1),
        selectedSize: json['selected_size']?.toString(),
        imageUrl: json['image_url']?.toString(),
      );
}

// ─── Offer Model ───────────────────────────────────────────────
class Offer {
  final String id;
  final String code;
  final int discountPercent;
  final String description;

  const Offer({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.description,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id']?.toString() ?? '',
        code: json['code'] ?? '',
        discountPercent: _toInt(json['discount_percent']),
        description: json['description'] ?? '',
      );
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
