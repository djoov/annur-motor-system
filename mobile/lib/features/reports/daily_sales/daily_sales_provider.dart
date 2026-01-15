import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../history/models/transaction_model.dart';

class DailySalesItem {
  final String itemName;
  final int quantity;
  final int totalRevenue;
  final int totalProfit;

  DailySalesItem({
    required this.itemName,
    required this.quantity,
    required this.totalRevenue,
    required this.totalProfit,
  });
}

class DailySalesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _streamSubscription;

  DateTime _selectedDate = DateTime.now();
  List<DailySalesItem> _salesItems = [];
  List<TransactionModel> _transactions = []; // Stored raw transactions
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  List<DailySalesItem> get salesItems => _salesItems;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  // Summaries
  int get totalRevenue =>
      _salesItems.fold(0, (sum, item) => sum + item.totalRevenue);
  int get totalProfit =>
      _salesItems.fold(0, (sum, item) => sum + item.totalProfit);
  int get totalItemsSold =>
      _salesItems.fold(0, (sum, item) => sum + item.quantity);

  DailySalesProvider() {
    listenToDailySales();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    listenToDailySales();
  }

  void listenToDailySales() {
    _isLoading = true;
    notifyListeners();

    _streamSubscription?.cancel();

    // Define start and end of selected day
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    try {
      _streamSubscription = _db
          .collection('transactions')
          .where('transactionDate', isGreaterThanOrEqualTo: startOfDay)
          .where('transactionDate', isLessThanOrEqualTo: endOfDay)
          .snapshots()
          .listen(
            (snapshot) {
              final transactions = snapshot.docs
                  .map((doc) => TransactionModel.fromFirestore(doc))
                  .toList();

              _transactions = transactions; // Store raw data

              _processTransactions(transactions);

              _isLoading = false;
              notifyListeners();
            },
            onError: (e) {
              print("Error listening to daily sales: $e");
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

  void _processTransactions(List<TransactionModel> transactions) {
    final Map<String, DailySalesItem> aggregatedItems = {};

    for (var transaction in transactions) {
      for (var item in transaction.items) {
        // Use itemName as key (or itemId if available and reliable, but name is safer for display grouping if IDs change or are missing)
        // Assuming unique names for simplicity or acceptable grouping by name
        final key = item.itemName;
        final revenue = item.sellPrice * item.quantity;
        final profit = (item.sellPrice - item.buyPrice) * item.quantity;

        if (aggregatedItems.containsKey(key)) {
          final existing = aggregatedItems[key]!;
          aggregatedItems[key] = DailySalesItem(
            itemName: key,
            quantity: existing.quantity + item.quantity,
            totalRevenue: existing.totalRevenue + revenue,
            totalProfit: existing.totalProfit + profit,
          );
        } else {
          aggregatedItems[key] = DailySalesItem(
            itemName: key,
            quantity: item.quantity,
            totalRevenue: revenue,
            totalProfit: profit,
          );
        }
      }
    }

    _salesItems = aggregatedItems.values.toList();
    // Sort by Revenue descending
    _salesItems.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
