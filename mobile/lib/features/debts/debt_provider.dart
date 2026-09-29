import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/debt_model.dart';

class DebtProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<DebtModel> _debts = [];
  bool _isLoading = false;

  // Cache for customer total debts if needed, or we just rely on CustomerProvider
  // We primarily list Debts here.

  List<DebtModel> get debts => _debts;
  bool get isLoading => _isLoading;

  StreamSubscription<QuerySnapshot>? _streamSubscription;

  DebtProvider() {
    listenToDebts();
  }

  void listenToDebts() {
    _isLoading = true;
    notifyListeners();
    _streamSubscription?.cancel();

    // Listen to all incomplete debts usually
    // Or we filter by status != 'paid'
    try {
      _streamSubscription = _db
          .collection('debts')
          .snapshots()
          .listen(
            (snapshot) {
              _debts = snapshot.docs
                  .map((doc) {
                    try {
                      return DebtModel.fromFirestore(doc);
                    } catch (e) {
                      print("Error parsing debt ${doc.id}: $e");
                      return null;
                    }
                  })
                  .whereType<DebtModel>()
                  .where((d) => d.status == 'unpaid' || d.status == 'partial')
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _isLoading = false;
              notifyListeners();
            },
            onError: (e) {
              print("Error listening to debts: $e");
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      print("Error listening to debts: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new debt (Usually called from POS Provider, not UI directly)
  Future<void> createDebt({
    required String customerId,
    required String customerName,
    required String transactionId,
    required int amount,
    DateTime? dueDate,
  }) async {
    try {
      final docRef = _db.collection('debts').doc();
      final now = DateTime.now();

      final newDebt = DebtModel(
        id: docRef.id,
        customerId: customerId,
        customerName: customerName,
        transactionId: transactionId,
        totalAmount: amount,
        remainingAmount: amount,
        status: 'unpaid',
        createdAt: now,
        updatedAt: now,
        dueDate: dueDate,
        logs: [],
      );

      final batch = _db.batch();
      batch.set(docRef, newDebt.toMap());

      // Update Customer total debt
      final customerRef = _db.collection('customers').doc(customerId);
      batch.update(customerRef, {
        'totalDebt': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print("Error creating debt: $e");
      throw e;
    }
  }

  Future<void> payDebt(String debtId, int paymentAmount, String note) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = _db.collection('debts').doc(debtId);

      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("Debt not found");

        final debt = DebtModel.fromFirestore(snapshot);

        if (paymentAmount > debt.remainingAmount) {
          throw Exception("Payment amount exceeds remaining debt");
        }

        final newRemaining = debt.remainingAmount - paymentAmount;
        final newStatus = newRemaining == 0 ? 'paid' : 'partial';

        final paymentLog = {
          'date': Timestamp.now(),
          'amount': paymentAmount,
          'note': note,
        };

        transaction.update(docRef, {
          'remainingAmount': newRemaining,
          'status': newStatus,
          'logs': FieldValue.arrayUnion([paymentLog]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Decrease customer total debt
        final customerRef = _db.collection('customers').doc(debt.customerId);
        transaction.update(customerRef, {
          'totalDebt': FieldValue.increment(-paymentAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print("Error paying debt: $e");
      rethrow;
    } finally {
      // The stream will update UI automatically
      _isLoading = false;
      notifyListeners();
    }
  }
}
