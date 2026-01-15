import 'package:cloud_firestore/cloud_firestore.dart';

class OpnameItem {
  final String itemId;
  final String itemName;
  final int systemStock;
  final int actualStock;
  final int difference; // actual - system
  final String? note;

  OpnameItem({
    required this.itemId,
    required this.itemName,
    required this.systemStock,
    required this.actualStock,
    required this.difference,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'systemStock': systemStock,
      'actualStock': actualStock,
      'difference': difference,
      'note': note,
    };
  }

  factory OpnameItem.fromMap(Map<String, dynamic> map) {
    return OpnameItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      systemStock: map['systemStock']?.toInt() ?? 0,
      actualStock: map['actualStock']?.toInt() ?? 0,
      difference: map['difference']?.toInt() ?? 0,
      note: map['note'],
    );
  }
}

class StockOpname {
  final String id;
  final DateTime date;
  final String staffId;
  final String staffName;
  final String status; // 'draft', 'finalized'
  final List<OpnameItem> items;
  final String? note;

  StockOpname({
    required this.id,
    required this.date,
    required this.staffId,
    required this.staffName,
    required this.status,
    required this.items,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'staffId': staffId,
      'staffName': staffName,
      'status': status,
      'items': items.map((x) => x.toMap()).toList(),
      'note': note,
    };
  }

  factory StockOpname.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StockOpname(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
      status: data['status'] ?? 'draft',
      items: List<OpnameItem>.from(
        (data['items'] as List<dynamic>? ?? []).map(
          (x) => OpnameItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      note: data['note'],
    );
  }
}
