import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'purchase_model.dart';
import '../items/items_provider.dart';

class PurchasesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Purchase> _purchases = [];
  bool _isLoading = false;

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;

  Future<void> fetchPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('purchases')
          .orderBy('date', descending: true)
          .get();
      _purchases = snapshot.docs
          .map((doc) => Purchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching purchases: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPurchase(
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

      // 1. Create Purchase Transaction
      await _db.collection('purchases').add({
        'supplierId': supplierId,
        'supplierName': supplierName,
        'total': total,
        'date': FieldValue.serverTimestamp(),
        'items': items.map((e) => e.toMap()).toList(),
      });

      // 2. Update Stock & Buy Price for each item
      final batch = _db.batch();
      for (var item in items) {
        final itemRef = _db.collection('items').doc(item.itemId);
        // We use check logic in cloud functions ideally, but here we do simple client-side increment
        batch.update(itemRef, {
          'stock': FieldValue.increment(item.quantity),
          'buyPrice': item.buyPrice, // Update latest buy price
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

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
}
