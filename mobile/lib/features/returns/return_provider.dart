import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// Process a return for specific items from a transaction
  Future<bool> processReturn({
    required String originalTransactionId,
    required List<Map<String, dynamic>>
    itemsToReturn, // {itemId, quantity, sellPrice, buyPrice, itemName}
    required String customerId,
    required String customerName,
  }) async {
    if (originalTransactionId.isEmpty) {
      print("Error: originalTransactionId is empty");
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final batch = _db.batch();
      final returnRef = _db.collection('transactions').doc();

      // Calculate totals (negative for return)
      int totalReturnAmount = 0;
      int totalReturnProfit = 0;

      List<Map<String, dynamic>> returnItemsData = [];

      for (var item in itemsToReturn) {
        int qty = item['quantity'];
        int sellPrice = item['sellPrice'];
        int buyPrice = item['buyPrice'];

        int itemTotal = qty * sellPrice;
        int itemProfit = qty * (sellPrice - buyPrice);

        totalReturnAmount += itemTotal;
        totalReturnProfit += itemProfit;

        returnItemsData.add({
          'itemId': item['itemId'],
          'itemName': item['itemName'],
          'quantity': -qty, // Negative quantity
          'sellPrice': sellPrice,
          'buyPrice': buyPrice,
          'category': item['category'] ?? 'Retur',
          'note': 'Retur dari TRX: ${originalTransactionId.substring(0, 8)}',
        });

        final itemId = item['itemId'];
        final itemName = item['itemName'];

        print("DEBUG: Processing Return Item '$itemName' (ID: $itemId)");

        if (itemId == null || (itemId as String).isEmpty) {
          print("ERROR: Skipping item '$itemName' because ID is empty/null");
          continue;
        }

        // DEBUG: Check if document actually exists (Temporary for debugging)
        final itemDocCheck = await _db.collection('items').doc(itemId).get();
        if (!itemDocCheck.exists) {
          print("ERROR: Item Document $itemId does NOT exist in Firestore!");
          // Try to find by name? (Optional fallback, maybe later blocks)
          continue;
        } else {
          print(
            "DEBUG: Item Document found. Current Stock: ${itemDocCheck.data()?['stock']}",
          );
        }

        // Calculate New Stock Logic (Handles Legacy Data)
        final data = itemDocCheck.data() as Map<String, dynamic>;

        // If qty_display is missing, use stock.
        final currentDisplayStock = data['qty_display'] ?? data['stock'] ?? 0;
        final newStock = currentDisplayStock + qty;

        print(
          "DEBUG: Updating Stock for '$itemName'. Old: $currentDisplayStock, New: $newStock",
        );

        // Update Stock: Set absolute value to ensure legacy sync
        final itemRef = _db.collection('items').doc(itemId);
        batch.update(itemRef, {
          'qty_display': newStock,
          'stock': newStock, // Keep legacy field synced
        });
      }

      // Create Return Transaction Record
      batch.set(returnRef, {
        'transactionDate': FieldValue.serverTimestamp(),
        'customerId': customerId,
        'customerName': customerName,
        'paymentMethod': 'refund', // or cash
        'status': 'returned',
        'type': 'return',
        'originalTransactionId': originalTransactionId,
        'totalAmount': -totalReturnAmount, // Negative amount
        'totalProfit': -totalReturnProfit, // Negative profit (loss of profit)
        'items': returnItemsData,
        'note': 'Retur Barang',
      });

      // Update Original Transaction
      final originalRef = _db
          .collection('transactions')
          .doc(originalTransactionId);

      Map<String, dynamic> originalUpdates = {'has_return': true};

      for (var item in itemsToReturn) {
        // Using dot notation for merge set to create/update nested fields
        originalUpdates['returned_items.${item['itemId']}'] =
            FieldValue.increment(item['quantity']);
      }

      // Use set with merge to ensure returned_items map is created if it doesn't exist
      batch.set(originalRef, originalUpdates, SetOptions(merge: true));

      await batch.commit();

      return true;
    } catch (e) {
      print("Return Failed: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
