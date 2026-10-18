import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _totalSales = 0;
  int _todayProfit = 0;
  int _transactionCount = 0;
  int _customerCount = 0;
  int _totalUnpaidDebt = 0;
  int _totalItemsCount = 0;
  bool _isLoading = false;

  int get totalSales => _totalSales;
  int get todayProfit => _todayProfit;
  int get transactionCount => _transactionCount;
  int get customerCount => _customerCount;
  int get totalUnpaidDebt => _totalUnpaidDebt;
  int get totalItemsCount => _totalItemsCount;
  bool get isLoading => _isLoading;
  Map<String, double> get weeklyRevenue => _weeklyRevenue;

  Map<String, double> _weeklyRevenue = {};

  // Top Items, Low Stock, Recent Transactions
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  List<Map<String, dynamic>> get topItems => _topItems;
  List<Map<String, dynamic>> get lowStockItems => _lowStockItems;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;

  StreamSubscription<QuerySnapshot>? _streamSubscription;

  DashboardProvider() {
    fetchStats();
  }

  void fetchStats() {
    _isLoading = true;
    notifyListeners();

    _streamSubscription?.cancel();
    _fetchLowStockItems();
    _fetchItemCount();

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(const Duration(days: 6));
      final startOfDay = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      // Listen to Transactions from last 7 days
      _streamSubscription = _db
          .collection('transactions')
          .where('transactionDate', isGreaterThanOrEqualTo: startOfDay)
          .orderBy('transactionDate', descending: true)
          .snapshots()
          .listen(
            (snapshot) async {
              int tempTotalSalesToday = 0;
              int tempTodayProfit = 0;
              int tempTransactionsToday = 0;
              Map<String, double> tempWeeklyRevenue = {};
              Map<String, int> itemSalesMap = {};
              List<Map<String, dynamic>> tempRecent = [];

              for (int i = 0; i < 7; i++) {
                final date = now.subtract(Duration(days: 6 - i));
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                tempWeeklyRevenue[dateKey] = 0.0;
              }

              final todayKey = DateFormat('yyyy-MM-dd').format(now);

              for (var doc in snapshot.docs) {
                final data = doc.data();
                final amount = (data['totalAmount'] as num? ?? 0).toDouble();
                final profit = (data['totalProfit'] as num? ?? 0).toInt();
                final dateTimestamp = data['transactionDate'] as Timestamp?;

                if (dateTimestamp != null) {
                  final date = dateTimestamp.toDate();
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);

                  if (tempWeeklyRevenue.containsKey(dateKey)) {
                    tempWeeklyRevenue[dateKey] =
                        (tempWeeklyRevenue[dateKey] ?? 0) + amount;
                  }

                  if (dateKey == todayKey) {
                    tempTotalSalesToday += amount.toInt();
                    tempTodayProfit += profit;
                    tempTransactionsToday++;
                  }

                  if (data['items'] != null) {
                    final itemsList = data['items'] as List<dynamic>;
                    for (var item in itemsList) {
                      final name = item['name'] ?? item['itemName'] ?? 'Unknown';
                      final qty = (item['quantity'] as num? ?? 0).toInt();
                      itemSalesMap[name] = (itemSalesMap[name] ?? 0) + qty;
                    }
                  }

                  // Recent transactions feed (take latest 5)
                  if (tempRecent.length < 5) {
                    tempRecent.add({
                      'id': doc.id,
                      'customerName': data['customerName'] ?? 'Pelanggan Umum',
                      'totalAmount': amount.toInt(),
                      'paymentMethod': data['paymentMethod'] ?? 'cash',
                      'status': data['status'] ?? 'paid',
                      'date': date,
                      'itemsCount': (data['items'] as List<dynamic>?)?.length ?? 0,
                    });
                  }
                }
              }

              _weeklyRevenue = tempWeeklyRevenue;
              _totalSales = tempTotalSalesToday;
              _todayProfit = tempTodayProfit;
              _transactionCount = tempTransactionsToday;
              _recentTransactions = tempRecent;

              final sortedEntries = itemSalesMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              _topItems = sortedEntries
                  .take(5)
                  .map((e) => {'name': e.key, 'quantity': e.value})
                  .toList();

              await _fetchCustomerCount();

              _isLoading = false;
              notifyListeners();
            },
            onError: (e) {
              print("Error listening to dashboard stats: $e");
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

  Future<void> _fetchLowStockItems() async {
    try {
      final snapshot = await _db
          .collection('items')
          .where('qty_display', isLessThanOrEqualTo: 5)
          .limit(10)
          .get();

      _lowStockItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'stock': data['qty_display'] ?? data['stock'] ?? 0,
          'code': data['code'] ?? '',
          'image': data['imageUrl'],
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print("Error fetching low stock: $e");
    }
  }

  Future<void> _fetchItemCount() async {
    try {
      final countQuery = await _db.collection('items').count().get();
      _totalItemsCount = countQuery.count ?? 0;
      notifyListeners();
    } catch (e) {
      print("Error fetching item count: $e");
    }
  }

  Future<void> _fetchCustomerCount() async {
    try {
      final snapshot = await _db.collection('customers').get();
      _customerCount = snapshot.docs.length;
      int totalDebt = 0;
      for (var doc in snapshot.docs) {
        // Both apps maintain `totalDebt`; `debt` is the old field name.
        final data = doc.data();
        final debt = ((data['totalDebt'] ?? data['debt']) as num?)?.toInt() ?? 0;
        totalDebt += debt;
      }
      _totalUnpaidDebt = totalDebt;
    } catch (e) {
      print("Error fetching customer count: $e");
    }
  }

  Future<void> refresh() async {
    fetchStats();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
