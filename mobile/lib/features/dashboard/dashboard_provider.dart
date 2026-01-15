import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _totalSales = 0;
  int _transactionCount = 0;
  int _customerCount = 0;
  bool _isLoading = false;

  int get totalSales => _totalSales;
  int get transactionCount => _transactionCount;
  int get customerCount => _customerCount;
  bool get isLoading => _isLoading;
  Map<String, double> get weeklyRevenue => _weeklyRevenue;

  Map<String, double> _weeklyRevenue = {};

  // Top Items & Low Stock
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _lowStockItems = [];

  List<Map<String, dynamic>> get topItems => _topItems;
  List<Map<String, dynamic>> get lowStockItems => _lowStockItems;

  StreamSubscription<QuerySnapshot>? _streamSubscription;

  DashboardProvider() {
    fetchStats();
  }

  void fetchStats() {
    _isLoading = true;
    notifyListeners();

    _streamSubscription?.cancel();
    _fetchLowStockItems(); // Fetch separatedly

    try {
      final now = DateTime.now();
      // Start from 6 days ago (total 7 days including today)
      final startOfWeek = now.subtract(const Duration(days: 6));
      final startOfDay = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      ); // Strip time

      // Listen to Transactions from last 7 days
      _streamSubscription = _db
          .collection('transactions')
          .where('transactionDate', isGreaterThanOrEqualTo: startOfDay)
          .snapshots()
          .listen(
            (snapshot) async {
              int tempTotalSalesToday = 0;
              int tempTransactionsToday = 0;
              Map<String, double> tempWeeklyRevenue = {};
              Map<String, int> itemSalesMap = {}; // name -> qty

              // Initialize map with 0 for last 7 days to ensure chart has all days
              for (int i = 0; i < 7; i++) {
                final date = now.subtract(
                  Duration(days: 6 - i),
                ); // -6, -5, ... 0
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                tempWeeklyRevenue[dateKey] = 0.0;
              }

              final todayKey = DateFormat('yyyy-MM-dd').format(now);

              for (var doc in snapshot.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['totalAmount'] as num? ?? 0).toDouble();
                final dateTimestamp = data['transactionDate'] as Timestamp?;

                if (dateTimestamp != null) {
                  final date = dateTimestamp.toDate();
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);

                  // Update Weekly Map
                  if (tempWeeklyRevenue.containsKey(dateKey)) {
                    tempWeeklyRevenue[dateKey] =
                        (tempWeeklyRevenue[dateKey] ?? 0) + amount;
                  }

                  // Update Today Stats
                  if (dateKey == todayKey) {
                    tempTotalSalesToday += amount.toInt();
                    tempTransactionsToday++;
                  }

                  // Aggregate Items
                  if (data['items'] != null) {
                    final itemsList = data['items'] as List<dynamic>;
                    for (var item in itemsList) {
                      final name = item['name'] ?? 'Unknown';
                      final qty = (item['quantity'] as num? ?? 0).toInt();
                      itemSalesMap[name] = (itemSalesMap[name] ?? 0) + qty;
                    }
                  }
                }
              }

              _weeklyRevenue = tempWeeklyRevenue;
              _totalSales = tempTotalSalesToday;
              _transactionCount = tempTransactionsToday;

              // Sort Top Items
              final sortedEntries = itemSalesMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              _topItems = sortedEntries
                  .take(5)
                  .map((e) => {'name': e.key, 'quantity': e.value})
                  .toList();

              // Fetch customer count occasionally or when transactions update
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
      // Query items with stock < 5
      // Since we have multiple stocks (display/warehouse), checking display logic for now
      // ideally we check both or total. Firestore only allows simple queries.
      // We will fetch where qty_display < 5.

      final snapshot = await _db
          .collection('items')
          .where('qty_display', isLessThan: 5)
          .orderBy('qty_display') // Required for inequality query
          .limit(10)
          .get();

      _lowStockItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'Unknown',
          'stock': data['qty_display'] ?? 0,
          'image': data['imageUrl'],
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print("Error fetching low stock: $e");
    }
  }

  Future<void> _fetchCustomerCount() async {
    try {
      final countQuery = await _db.collection('customers').count().get();
      _customerCount = countQuery.count ?? 0;
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
