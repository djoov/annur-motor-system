import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stock_opname_model.dart';

class StockOpnameProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<StockOpname> _history = [];
  bool _isLoading = false;

  StockOpnameProvider() {
    fetchHistory();
  }

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
        .snapshots()
        .listen(
          (snapshot) {
            _history = snapshot.docs.map((doc) {
              try {
                return StockOpname.fromFirestore(doc);
              } catch (e) {
                print("Error parsing stock opname ${doc.id}: $e");
                return null;
              }
            }).whereType<StockOpname>().toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            print("Error listening to stock opnames: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
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

      final changed = _activeItems.where((i) => i.difference != 0).toList();

      // Save the record and apply the counted difference atomically. Applying
      // the difference to the *current* stock keeps any sales made between
      // counting and finalizing. Writes the real stock fields (`stock` +
      // mirrored `qty_display`) — the old code wrote an unused `stockDisplay`
      // field, so adjustments never reached the shop's stock.
      await _db.runTransaction((tx) async {
        final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final item in changed) {
          snaps[item.itemId] =
              await tx.get(_db.collection('items').doc(item.itemId));
        }

        tx.set(opnameRef, opname.toMap());

        for (final item in changed) {
          final snap = snaps[item.itemId]!;
          if (!snap.exists) continue;
          final data = snap.data()!;
          final current =
              ((data['stock'] ?? data['qty_display'] ?? data['qty_warehouse'])
                          as num?)
                      ?.toInt() ??
                  0;
          final updated = (current + item.difference).clamp(0, 1 << 31);
          tx.update(snap.reference, {
            'stock': updated,
            'qty_display': updated,
            'lastOpnameDate': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

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
