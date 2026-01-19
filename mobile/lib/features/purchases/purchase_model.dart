import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItem {
  final String itemId;
  final String name;
  final int buyPrice;
  final int quantity;

  PurchaseItem({
    required this.itemId,
    required this.name,
    required this.buyPrice,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'buyPrice': buyPrice,
      'quantity': quantity,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      buyPrice: map['buyPrice'] ?? 0,
      quantity: map['quantity'] ?? 0,
    );
  }
}

class Purchase {
  final String id;
  final String invoiceNumber; // Added invoice number
  final String supplierId;
  final String supplierName;
  final int total;
  final DateTime date;
  final List<PurchaseItem> items;

  Purchase({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.total,
    required this.date,
    required this.items,
  });

  factory Purchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Purchase(
      id: doc.id,
      invoiceNumber:
          data['invoiceNumber'] ?? doc.id.substring(0, 8).toUpperCase(),
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? 'Unknown',
      total: data['total'] ?? 0,
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      items:
          (data['items'] as List<dynamic>?)
              ?.map((e) => PurchaseItem.fromMap(e))
              .toList() ??
          [],
    );
  }
}
