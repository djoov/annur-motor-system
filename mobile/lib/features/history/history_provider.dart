import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/transaction_model.dart';

class HistoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;
  StreamSubscription<QuerySnapshot>? _streamSubscription;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  // Summaries
  // Return double but cast/round as needed, or ensure model has double.
  // Assuming model uses double for amounts but int is requested.
  // Let's use double to be safe and efficient.
  double get totalRevenue =>
      _transactions.fold(0, (sum, item) => sum + item.totalAmount);
  double get totalProfit =>
      _transactions.fold(0, (sum, item) => sum + item.totalProfit);
  int get totalTransactions => _transactions.length;

  HistoryProvider() {
    // Start listening immediately
    fetchTransactions();
  }

  Future<void> setDateRange(DateTimeRange? range) async {
    _selectedDateRange = range;
    fetchTransactions();
  }

  // Renamed back to fetchTransactions to keep compatibility with UI call,
  // but it implements STREAM logic.
  void fetchTransactions() {
    // Only show full loading state if we have no data to show
    if (_transactions.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    // logic continues...

    _streamSubscription?.cancel();

    try {
      Query query = _db
          .collection('transactions')
          .orderBy('transactionDate', descending: true);

      if (_selectedDateRange != null) {
        // Filter by date range
        query = query
            .where(
              'transactionDate',
              isGreaterThanOrEqualTo: _selectedDateRange!.start,
            )
            .where(
              'transactionDate',
              isLessThanOrEqualTo: _selectedDateRange!.end.add(
                const Duration(days: 1),
              ),
            );
      } else {
        // Default limit if no filter
        // Optimized: Reduced from 100 to 30 for faster initial load
        query = query.limit(30);
      }

      print("Refetching Transactions...");
      _streamSubscription = query.snapshots().listen(
        (snapshot) {
          print("Transactions Snapshot Received: ${snapshot.docs.length} docs");
          _transactions = snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          print("Error listening to transactions: $e");
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print("Error setting up stream: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a single transaction (Admin only)
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _db.collection('transactions').doc(transactionId).delete();
      // Stream will auto-update the list
      return true;
    } catch (e) {
      print("Error deleting transaction: $e");
      return false;
    }
  }

  // Delete multiple transactions (Admin only - for batch cleanup)
  Future<int> deleteMultipleTransactions(List<String> transactionIds) async {
    int deletedCount = 0;
    final batch = _db.batch();

    try {
      for (final id in transactionIds) {
        batch.delete(_db.collection('transactions').doc(id));
        deletedCount++;
      }
      await batch.commit();
      return deletedCount;
    } catch (e) {
      print("Error batch deleting transactions: $e");
      return deletedCount;
    }
  }

  Future<void> refresh() async {
    // Just restart the listener
    fetchTransactions();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
