import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String code;
  final int sellPrice;
  final int buyPrice;
  final int stockDisplay; // Unified Single Stock
  final String? category;
  final String? imageUrl;
  final List<String> tags;
  final String? locationDisplay;
  final String? description;

  // Backward compatibility getters
  int get stock => stockDisplay;
  int get stockWarehouse => 0;
  int get priceWorkshop => sellPrice;
  String? get locationWarehouse => locationDisplay;

  Item({
    required this.id,
    required this.name,
    required this.code,
    required this.sellPrice,
    required this.buyPrice,
    required this.stockDisplay,
    int? priceWorkshop,
    int? stockWarehouse,
    this.tags = const [],
    this.category,
    this.imageUrl,
    this.locationDisplay,
    String? locationWarehouse,
    this.description,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ??
            double.tryParse(value)?.toInt() ??
            defaultValue;
      }
      return defaultValue;
    }

    // Unified stock calculation (takes 'stock', 'qty_display', or falls back to 'qty_warehouse')
    final unifiedStock = parseInt(data['stock'] ?? data['qty_display'] ?? data['qty_warehouse']);
    final unifiedLocation = data['location_display']?.toString() ?? data['location']?.toString() ?? data['location_warehouse']?.toString();

    return Item(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      code: data['code']?.toString() ?? '',
      sellPrice: parseInt(data['sellPrice']),
      buyPrice: parseInt(data['buyPrice']),
      stockDisplay: unifiedStock,
      tags: data['tags'] is List
          ? (data['tags'] as List).map((e) => e.toString()).toList()
          : [],
      category: data['category']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      locationDisplay: unifiedLocation,
      description: data['description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'sellPrice': sellPrice,
      'buyPrice': buyPrice,
      'stock': stockDisplay,
      'qty_display': stockDisplay,
      'tags': tags,
      'category': category,
      'imageUrl': imageUrl,
      'location_display': locationDisplay,
      'location': locationDisplay,
      'description': description,
    };
  }
}

class CartItem extends Item {
  int quantity;

  CartItem({required Item item, this.quantity = 1})
    : super(
        id: item.id,
        name: item.name,
        code: item.code,
        sellPrice: item.sellPrice,
        buyPrice: item.buyPrice,
        stockDisplay: item.stockDisplay,
        tags: item.tags,
        category: item.category,
        imageUrl: item.imageUrl,
        locationDisplay: item.locationDisplay,
        description: item.description,
      );
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final int debt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.debt = 0,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ??
            double.tryParse(value)?.toInt() ??
            defaultValue;
      }
      return defaultValue;
    }

    return Customer(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      debt: parseInt(data['totalDebt'] ?? data['debt']),
    );
  }
}
