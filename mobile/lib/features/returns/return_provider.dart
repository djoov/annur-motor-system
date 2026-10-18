import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// How a processed return was settled.
class ReturnResult {
  /// Taken off the customer's open debt (debt sales).
  final int debtReduced;

  /// Cash to hand back to the customer.
  final int cashRefund;

  const ReturnResult({required this.debtReduced, required this.cashRefund});
}

class ReturnProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// Process a return for specific items from a transaction.
  ///
  /// Everything happens in one Firestore transaction: stock goes back, the
  /// negative "return" transaction is recorded, the original transaction's
  /// `returned_items` is raised, and for a debt sale the open debt is reduced
  /// first (only the part above the remaining debt is refunded in cash).
  /// Throws with a readable message on failure.
  Future<ReturnResult> processReturn({
    required String originalTransactionId,
    required List<Map<String, dynamic>>
    itemsToReturn, // {itemId, quantity, sellPrice, buyPrice, itemName}
    required String customerId,
    required String customerName,
  }) async {
    if (originalTransactionId.isEmpty) {
      throw Exception("Transaksi asal tidak dikenali.");
    }

    _isLoading = true;
    notifyListeners();

    try {
      final originalRef =
          _db.collection('transactions').doc(originalTransactionId);
      final returnRef = _db.collection('transactions').doc();

      // Queries can't run inside a transaction: find the sale's debt first,
      // then read it again inside the transaction.
      final debtQuery = await _db
          .collection('debts')
          .where('transactionId', isEqualTo: originalTransactionId)
          .limit(1)
          .get();
      final debtRef =
          debtQuery.docs.isEmpty ? null : debtQuery.docs.first.reference;

      int totalReturnAmount = 0;
      int totalReturnProfit = 0;
      final qtyById = <String, int>{};
      final returnItemsData = <Map<String, dynamic>>[];

      for (final item in itemsToReturn) {
        final itemId = (item['itemId'] as String?) ?? '';
        final qty = item['quantity'] as int;
        final sellPrice = item['sellPrice'] as int;
        final buyPrice = item['buyPrice'] as int;
        if (itemId.isEmpty || qty <= 0) continue;

        totalReturnAmount += qty * sellPrice;
        totalReturnProfit += qty * (sellPrice - buyPrice);
        qtyById[itemId] = (qtyById[itemId] ?? 0) + qty;

        returnItemsData.add({
          'itemId': itemId,
          'itemName': item['itemName'],
          'quantity': -qty, // Negative quantity
          'sellPrice': sellPrice,
          'buyPrice': buyPrice,
          'category': item['category'] ?? 'Retur',
          'note': 'Retur dari TRX: ${originalTransactionId.substring(0, 8)}',
        });
      }
      if (qtyById.isEmpty) throw Exception("Tidak ada barang yang diretur.");

      final result = await _db.runTransaction<ReturnResult>((tx) async {
        // --- reads ---
        final originalSnap = await tx.get(originalRef);
        if (!originalSnap.exists) {
          throw Exception("Transaksi asal sudah dihapus.");
        }
        final original = originalSnap.data()!;

        final itemSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final itemId in qtyById.keys) {
          itemSnaps[itemId] =
              await tx.get(_db.collection('items').doc(itemId));
        }
        final debtSnap = debtRef == null ? null : await tx.get(debtRef);

        // --- validate: never return more than was bought (also guards two
        // devices returning the same sale at once) ---
        final bought = <String, int>{};
        for (final raw in (original['items'] as List? ?? const [])) {
          final m = raw as Map<String, dynamic>;
          final id = (m['itemId'] ?? m['id'] ?? '') as String;
          bought[id] = (bought[id] ?? 0) + ((m['quantity'] as num?)?.toInt() ?? 0);
        }
        final alreadyReturned = returnedItemsOf(original);
        for (final entry in qtyById.entries) {
          final left = (bought[entry.key] ?? 0) - (alreadyReturned[entry.key] ?? 0);
          if (entry.value > left) {
            throw Exception(
              "Sebagian barang sudah diretur sebelumnya. Buka ulang transaksi ini.",
            );
          }
        }

        // --- settle against the open debt first ---
        int debtReduced = 0;
        if (debtSnap != null && debtSnap.exists) {
          final debt = debtSnap.data()!;
          final remaining = (debt['remainingAmount'] as num?)?.toInt() ?? 0;
          debtReduced = totalReturnAmount < remaining ? totalReturnAmount : remaining;
          if (debtReduced > 0) {
            final newRemaining = remaining - debtReduced;
            tx.update(debtSnap.reference, {
              'remainingAmount': newRemaining,
              'status': newRemaining == 0 ? 'paid' : 'partial',
              'logs': FieldValue.arrayUnion([
                {
                  'date': Timestamp.now(),
                  'amount': debtReduced,
                  'note': 'Retur barang',
                },
              ]),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            final debtCustomer = (debt['customerId'] as String?) ?? customerId;
            tx.update(_db.collection('customers').doc(debtCustomer), {
              'totalDebt': FieldValue.increment(-debtReduced),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        final cashRefund = totalReturnAmount - debtReduced;

        // --- writes ---
        for (final entry in qtyById.entries) {
          final snap = itemSnaps[entry.key]!;
          if (!snap.exists) continue; // item deleted: nothing to restock
          final data = snap.data()!;
          final current =
              ((data['stock'] ?? data['qty_display'] ?? data['qty_warehouse'])
                          as num?)
                      ?.toInt() ??
                  0;
          tx.update(snap.reference, {
            'stock': current + entry.value,
            'qty_display': current + entry.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        tx.set(returnRef, {
          'transactionDate': FieldValue.serverTimestamp(),
          'customerId': customerId,
          'customerName': customerName,
          'paymentMethod': cashRefund > 0 ? 'refund' : 'debt',
          'status': 'returned',
          'type': 'return',
          'originalTransactionId': originalTransactionId,
          'totalAmount': -totalReturnAmount, // Negative amount
          'totalProfit': -totalReturnProfit, // Negative profit (loss of profit)
          'debtReduced': debtReduced,
          'cashRefund': cashRefund,
          'items': returnItemsData,
          'note': 'Retur Barang',
        });

        // update() (unlike set) reads "a.b" as a nested field path.
        tx.update(originalRef, {
          'has_return': true,
          for (final entry in qtyById.entries)
            'returned_items.${entry.key}': FieldValue.increment(entry.value),
        });

        return ReturnResult(debtReduced: debtReduced, cashRefund: cashRefund);
      });

      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// `returned_items` of a transaction document: {itemId: quantity}.
  ///
  /// Older app versions wrote it with set(merge) + dotted keys, which stored
  /// literal top-level fields named "returned_items.<itemId>"; those are
  /// counted too so earlier returns still limit what can be returned.
  static Map<String, int> returnedItemsOf(Map<String, dynamic> data) {
    final result = <String, int>{};
    final nested = data['returned_items'];
    if (nested is Map) {
      nested.forEach((key, value) {
        if (value is num) result['$key'] = (result['$key'] ?? 0) + value.toInt();
      });
    }
    const prefix = 'returned_items.';
    data.forEach((key, value) {
      if (key.startsWith(prefix) && value is num) {
        final id = key.substring(prefix.length);
        result[id] = (result[id] ?? 0) + value.toInt();
      }
    });
    return result;
  }
}
