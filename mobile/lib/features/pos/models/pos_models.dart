import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String code;
  final int sellPrice;
  final int buyPrice;
  // final int stock; // Removed, now a getter
  final String? category;
  final String? imageUrl;
  final int priceWorkshop;
  final int stockDisplay;
  final int stockWarehouse;
  final List<String> tags;

  final String? locationDisplay;
  final String? locationWarehouse;
  final String? description;

  // Computed for backward compatibility
  int get stock => stockDisplay;

  Item({
    required this.id,
    required this.name,
    required this.code,
    required this.sellPrice,
    required this.buyPrice,
    required this.stockDisplay,
    this.priceWorkshop = 0,
    this.stockWarehouse = 0,
    this.tags = const [],
    this.category,
    this.imageUrl,
    this.locationDisplay,
    this.locationWarehouse,
    this.description,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      sellPrice: data['sellPrice'] ?? 0,
      buyPrice: data['buyPrice'] ?? 0,
      stockDisplay:
          data['qty_display'] ?? data['stock'] ?? 0, // Fallback to old stock
      stockWarehouse: data['qty_warehouse'] ?? 0,
      priceWorkshop:
          data['price_workshop'] ??
          data['sellPrice'] ??
          0, // Default to general price
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'],
      imageUrl: data['imageUrl'],
      locationDisplay: data['location_display'],
      locationWarehouse: data['location_warehouse'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'sellPrice': sellPrice,
      'buyPrice': buyPrice,
      'qty_display': stockDisplay,
      'stock': stockDisplay, // Keep legacy field synced
      'qty_warehouse': stockWarehouse,
      'price_workshop': priceWorkshop,
      'tags': tags,
      'category': category,
      'imageUrl': imageUrl,
      'location_display': locationDisplay,
      'location_warehouse': locationWarehouse,
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
        stockWarehouse: item.stockWarehouse,
        priceWorkshop: item.priceWorkshop,
        tags: item.tags,
        category: item.category,
        imageUrl: item.imageUrl,
        locationDisplay: item.locationDisplay,
        locationWarehouse: item.locationWarehouse,
        description: item.description,
      );
}

class Customer {
  final String id;
  final String name;

  Customer({required this.id, required this.name});

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(id: doc.id, name: data['name'] ?? '');
  }
}
