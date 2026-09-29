import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'purchase_model.dart';

class PurchasesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Purchase> _purchases = [];
  bool _isLoading = false;

  PurchasesProvider() {
    fetchPurchases();
  }

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;

  Future<void> fetchPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('purchases').get();
      _purchases = snapshot.docs.map((doc) {
        try {
          return Purchase.fromFirestore(doc);
        } catch (e) {
          print("Error parsing purchase ${doc.id}: $e");
          return null;
        }
      }).whereType<Purchase>().toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print("Error fetching purchases: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPurchase(
    String invoiceNumber,
    String supplierId,
    String supplierName,
    List<PurchaseItem> items,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      int total = 0;
      for (var item in items) {
        total += item.buyPrice * item.quantity;
      }

      // Record the purchase and add stock in one transaction. Both stock
      // fields (`stock` + mirrored `qty_display`) are set from the current
      // value so they stay in sync, including older items without `stock`.
      final purchaseRef = _db.collection('purchases').doc();
      await _db.runTransaction((tx) async {
        final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final item in items) {
          snaps[item.itemId] =
              await tx.get(_db.collection('items').doc(item.itemId));
        }

        tx.set(purchaseRef, {
          'invoiceNumber': invoiceNumber,
          'supplierId': supplierId,
          'supplierName': supplierName,
          'total': total,
          'date': FieldValue.serverTimestamp(),
          'items': items.map((e) => e.toMap()).toList(),
        });

        // Same item may appear twice in one purchase
        final added = <String, int>{};
        final lastPrice = <String, int>{};
        for (final item in items) {
          added[item.itemId] = (added[item.itemId] ?? 0) + item.quantity;
          lastPrice[item.itemId] = item.buyPrice;
        }

        for (final entry in added.entries) {
          final snap = snaps[entry.key]!;
          if (!snap.exists) continue;
          final data = snap.data()!;
          final current =
              ((data['stock'] ?? data['qty_display'] ?? data['qty_warehouse'])
                          as num?)
                      ?.toInt() ??
                  0;
          tx.update(snap.reference, {
            'stock': current + entry.value,
            'qty_display': current + entry.value,
            'buyPrice': lastPrice[entry.key], // latest buy price
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      await fetchPurchases();
      return true;
    } catch (e) {
      print("Error creating purchase: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Import purchase from CSV
  Future<bool> importPurchase({
    required String invoiceNumber,
    required String supplierName,
    required List<PurchaseItem> items,
  }) async {
    try {
      int total = 0;
      for (var item in items) {
        total += item.buyPrice * item.quantity;
      }

      // Create Purchase record with invoice number
      await _db.collection('purchases').add({
        'invoiceNumber': invoiceNumber,
        'supplierId': '',
        'supplierName': supplierName,
        'total': total,
        'date': FieldValue.serverTimestamp(),
        'items': items.map((e) => e.toMap()).toList(),
        'importedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error importing purchase: $e");
      return false;
    }
  }
}
