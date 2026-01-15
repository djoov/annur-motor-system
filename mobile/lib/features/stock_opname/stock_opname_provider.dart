import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stock_opname_model.dart';

class StockOpnameProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<StockOpname> _history = [];
  bool _isLoading = false;

  List<StockOpname> get history => _history;
  bool get isLoading => _isLoading;

  // Active Session
  List<OpnameItem> _activeItems = [];
  List<OpnameItem> get activeItems => _activeItems;

  void fetchHistory() {
    _isLoading = true;
    notifyListeners();

    _db
        .collection('stock_opnames')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
          _history = snapshot.docs
              .map((doc) => StockOpname.fromFirestore(doc))
              .toList();
          _isLoading = false;
          notifyListeners();
        });
  }

  void startNewOpname() {
    _activeItems = [];
    notifyListeners();
  }

  void addItemToOpname(
    String itemId,
    String itemName,
    int systemStock,
    int actualStock,
    String? note,
  ) {
    // Check if exists, update if so
    final index = _activeItems.indexWhere((item) => item.itemId == itemId);

    final newItem = OpnameItem(
      itemId: itemId,
      itemName: itemName,
      systemStock: systemStock,
      actualStock: actualStock,
      difference: actualStock - systemStock,
      note: note,
    );

    if (index >= 0) {
      _activeItems[index] = newItem;
    } else {
      _activeItems.add(newItem);
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _activeItems.removeWhere((item) => item.itemId == itemId);
    notifyListeners();
  }

  Future<void> finalizeOpname(
    String staffId,
    String staffName,
    String? note,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final opnameRef = _db.collection('stock_opnames').doc();
      final opname = StockOpname(
        id: opnameRef.id,
        date: DateTime.now(),
        staffId: staffId,
        staffName: staffName,
        status: 'finalized',
        items: _activeItems,
        note: note,
      );

      final batch = _db.batch();

      // 1. Save Opname Record
      batch.set(opnameRef, opname.toMap());

      // 2. Adjust Stock in Items Collection
      for (var item in _activeItems) {
        if (item.difference != 0) {
          final itemRef = _db.collection('items').doc(item.itemId);
          // Assuming we are adjusting DISPLAY stock for now.
          // Ideally, we might need to select which stock (warehouse vs display),
          // but usually opname is done on display first.
          // Let's increment by difference (difference can be negative)
          batch.update(itemRef, {
            'stockDisplay': FieldValue.increment(item.difference),
            'lastOpnameDate': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      _activeItems = []; // Clear
    } catch (e) {
      print("Error finalizing opname: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
