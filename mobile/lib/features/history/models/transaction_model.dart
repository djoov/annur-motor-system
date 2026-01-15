import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final int sellPrice; // Price at the time of transaction
  final int buyPrice;

  TransactionItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.sellPrice,
    required this.buyPrice,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      itemId: map['itemId'] ?? map['id'] ?? '',
      itemName: map['itemName'] ?? map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      sellPrice: map['sellPrice'] ?? 0,
      buyPrice: map['buyPrice'] ?? 0,
    );
  }
}

class TransactionModel {
  final String id;
  final DateTime date;
  final String customerId;
  final String customerName;
  final int totalAmount;
  final int totalProfit;
  final List<TransactionItem> items;
  final String type; // 'sale', 'return'
  final Map<String, int> returnedItems; // {itemId: quantity}
  final String paymentMethod;
  final String paymentStatus;
  final String cashierName;

  TransactionModel({
    required this.id,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.totalProfit,
    required this.items,
    this.type = 'sale',
    this.returnedItems = const {},
    this.paymentMethod = 'cash',
    this.paymentStatus = 'paid',
    this.cashierName = '-',
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle specific Timestamp object from Firestore
    DateTime date = DateTime.now();
    if (data['transactionDate'] != null) {
      if (data['transactionDate'] is Timestamp) {
        date = (data['transactionDate'] as Timestamp).toDate();
      }
    }

    var itemsList = <TransactionItem>[];
    if (data['items'] != null) {
      itemsList = (data['items'] as List)
          .map((i) => TransactionItem.fromMap(i))
          .toList();
    }

    // Parse returnedItems
    Map<String, int> returnedItemsMap = {};
    if (data['returned_items'] != null) {
      final mapData = data['returned_items'] as Map<String, dynamic>;
      mapData.forEach((key, value) {
        if (value is int) {
          returnedItemsMap[key] = value;
        }
      });
    }

    return TransactionModel(
      id: doc.id,
      date: date,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Umum',
      totalAmount: data['totalAmount'] ?? 0,
      totalProfit: data['totalProfit'] ?? 0,
      items: itemsList,
      type: data['type'] ?? 'sale',
      returnedItems: returnedItemsMap,
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentStatus: data['status'] ?? 'paid',
      cashierName: data['cashierName'] ?? '-',
    );
  }
}
