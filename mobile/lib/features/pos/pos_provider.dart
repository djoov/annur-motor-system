import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'models/pos_models.dart';

class PosProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  List<Customer> _customers = [];
  final List<CartItem> _cart = [];
  String _selectedCustomerId = 'umum';
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _itemsSubscription;
  StreamSubscription<QuerySnapshot>? _customersSubscription;

  // Payment State
  bool _isDebt = false;
  String _paymentType = 'cash'; // 'cash' or 'transfer'

  List<Item> get filteredItems => _filteredItems;
  List<Customer> get customers => _customers;
  List<CartItem> get cart => _cart;
  String get selectedCustomerId => _selectedCustomerId;
  bool get isLoading => _isLoading;
  bool get isDebt => _isDebt;
  String get paymentType => _paymentType;

  Customer? get selectedCustomer {
    if (_selectedCustomerId == 'umum') return null;
    try {
      return _customers.firstWhere((c) => c.id == _selectedCustomerId);
    } catch (_) {
      return null;
    }
  }

  PosProvider() {
    startListening();
  }

  // Setters
  void setDebt(bool value) {
    _isDebt = value;
    notifyListeners();
  }

  void setPaymentType(String value) {
    _paymentType = value;
    notifyListeners();
  }

  int get totalAmount =>
      _cart.fold(0, (sum, item) => sum + (item.sellPrice * item.quantity));
  int get totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);

  /// Start listening to real-time updates
  void startListening() {
    _isLoading = true;
    notifyListeners();

    // Listen to items
    _itemsSubscription?.cancel();
    _itemsSubscription = _db
        .collection('items')
        .snapshots()
        .listen(
          (snapshot) {
            _allItems = snapshot.docs.map((doc) {
              try {
                return Item.fromFirestore(doc);
              } catch (e) {
                print("Error parsing POS item ${doc.id}: $e");
                return null;
              }
            }).whereType<Item>().toList();

            _applyFilters();

            // Extract unique categories
            final catSet = _allItems.map((e) => e.category ?? 'Umum').toSet();
            _categories = ["Semua", ...catSet.toList()..sort()];

            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            print("Error listening to items: $e");
            _isLoading = false;
            notifyListeners();
          },
        );

    // Listen to customers
    _customersSubscription?.cancel();
    _customersSubscription = _db.collection('customers').snapshots().listen((
      snapshot,
    ) {
      _customers = snapshot.docs.map((doc) {
        try {
          return Customer.fromFirestore(doc);
        } catch (e) {
          print("Error parsing customer ${doc.id}: $e");
          return null;
        }
      }).whereType<Customer>().toList();
      notifyListeners();
    }, onError: (e) => print("Error listening to customers: $e"));
  }

  /// Stop listening (call on dispose)
  void stopListening() {
    _itemsSubscription?.cancel();
    _customersSubscription?.cancel();
    _itemsSubscription = null;
    _customersSubscription = null;
  }

  /// Legacy fetch for backward compatibility
  Future<void> fetchData() async {
    if (_itemsSubscription == null) {
      startListening();
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  List<String> _categories = ["Semua"];
  String _selectedCategory = "Semua";

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;

  void filterCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void searchItems(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  String _searchQuery = "";

  // ==========================================
  // 🧠 CONVENTIONAL AI / HEURISTIC ENGINE
  // ==========================================

  static const Map<String, List<String>> _synonymDict = {
    'kanpas': ['kampas', 'rem', 'pad', 'brake', 'tromol', 'cakram'],
    'kampas': ['kanpas', 'rem', 'pad', 'brake', 'tromol', 'cakram'],
    'rem': ['kampas', 'kanpas', 'brake', 'tromol', 'cakram', 'disc'],
    'vanbel': ['vanbelt', 'vbelt', 'v-belt', 'belt', 'tali'],
    'vanbelt': ['vanbel', 'vbelt', 'v-belt', 'belt', 'tali'],
    'vbelt': ['vanbelt', 'vanbel', 'v-belt', 'belt', 'tali'],
    'klahar': ['laher', 'bearing', 'lahar'],
    'laher': ['klahar', 'bearing', 'lahar'],
    'bearing': ['klahar', 'laher', 'lahar'],
    'sok': ['skok', 'shock', 'breaker', 'suspensi'],
    'skok': ['sok', 'shock', 'breaker', 'suspensi'],
    'shock': ['sok', 'skok', 'breaker', 'suspensi'],
    'lampu': ['bohlam', 'led', 'bulb', 'headlamp', 'stoplamp', 'sein'],
    'bohlam': ['lampu', 'led', 'bulb'],
    'gir': ['gear', 'sprocket', 'rantai'],
    'gear': ['gir', 'sprocket', 'rantai'],
    'karbu': ['karburator', 'carburetor'],
    'karburator': ['karbu', 'carburetor'],
    'injeksi': ['injector', 'injektor', 'fi'],
    'sil': ['seal', 'karet'],
    'seal': ['sil', 'karet'],
    'paking': ['gasket', 'seal', 'packing'],
    'gasket': ['paking', 'seal', 'packing'],
    'aki': ['accu', 'baterai', 'battery'],
    'accu': ['aki', 'baterai', 'battery'],
    'busi': ['spark', 'plug', 'ngk', 'denso'],
    'oli': ['oil', 'pelumas', 'lubricant'],
    'oil': ['oli', 'pelumas', 'lubricant'],
    'ban': ['tire', 'tubeless', 'tubetype', 'luar', 'dalam'],
    'kabel': ['cable', 'tali', 'kawat'],
  };

  /// Multi-token fuzzy search with synonym expansion and relevance scoring
  void _applyFilters() {
    List<Item> temp = _allItems;

    if (_selectedCategory != "Semua") {
      temp = temp.where((item) => item.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final rawTokens = _searchQuery
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      // Expand synonyms for each search token
      final Set<String> queryTokens = {};
      for (var token in rawTokens) {
        queryTokens.add(token);
        if (_synonymDict.containsKey(token)) {
          queryTokens.addAll(_synonymDict[token]!);
        }
      }

      final scoredItems = <MapEntry<Item, int>>[];

      for (var item in temp) {
        final itemName = item.name.toLowerCase();
        final itemCode = item.code.toLowerCase();
        final itemCategory = (item.category ?? '').toLowerCase();
        final itemTags = item.tags.map((t) => t.toLowerCase()).toList();

        int score = 0;

        // Exact code match = highest priority
        if (itemCode == _searchQuery.trim().toLowerCase()) {
          score += 1000;
        } else if (itemCode.contains(_searchQuery.trim().toLowerCase())) {
          score += 500;
        }

        // Exact full phrase match in name
        if (itemName.contains(_searchQuery.trim().toLowerCase())) {
          score += 300;
        }

        // Token match evaluation
        int matchedTokens = 0;
        for (var token in queryTokens) {
          bool tokenMatched = false;

          if (itemName.contains(token)) {
            score += 50;
            tokenMatched = true;
          }
          if (itemTags.any((t) => t.contains(token))) {
            score += 40;
            tokenMatched = true;
          }
          if (itemCategory.contains(token)) {
            score += 20;
            tokenMatched = true;
          }

          if (tokenMatched) matchedTokens++;
        }

        // If at least one primary token matched
        if (score > 0 || matchedTokens > 0) {
          scoredItems.add(MapEntry(item, score + (matchedTokens * 30)));
        }
      }

      // Sort by relevance score descending
      scoredItems.sort((a, b) => b.value.compareTo(a.value));
      temp = scoredItems.map((e) => e.key).toList();
    }

    _filteredItems = temp;
    notifyListeners();
  }

  /// 🎯 AI Smart Cross-Selling / Complementary Items
  /// Suggests related accessories based on current items in the cart
  List<Item> get smartCrossSellSuggestions {
    if (_cart.isEmpty) return [];

    final cartIds = _cart.map((c) => c.id).toSet();
    final cartNames = _cart.map((c) => c.name.toLowerCase()).join(' ');
    final cartCategories = _cart.map((c) => (c.category ?? '').toLowerCase()).toSet();

    final Set<String> targetKeywords = {};

    if (cartNames.contains('oli') || cartCategories.contains('oli') || cartCategories.contains('pelumas')) {
      targetKeywords.addAll(['gardan', 'gear oil', 'busi', 'filter']);
    }
    if (cartNames.contains('ban') || cartCategories.contains('ban')) {
      targetKeywords.addAll(['pentil', 'tubeless', 'cairan', 'dalam', 'ban dalam']);
    }
    if (cartNames.contains('rem') || cartNames.contains('kampas') || cartCategories.contains('rem')) {
      targetKeywords.addAll(['minyak rem', 'brake fluid', 'cakram', 'disc']);
    }
    if (cartNames.contains('rantai') || cartNames.contains('gir') || cartNames.contains('gear')) {
      targetKeywords.addAll(['chain lube', 'pelumas rantai', 'kancing rantai']);
    }
    if (cartNames.contains('vanbelt') || cartNames.contains('roller') || cartNames.contains('cvt')) {
      targetKeywords.addAll(['gemuk', 'grease', 'slider', 'cvt']);
    }
    if (cartNames.contains('busi')) {
      targetKeywords.addAll(['cangklong', 'tutup busi', 'oli']);
    }
    if (cartNames.contains('aki') || cartNames.contains('accu')) {
      targetKeywords.addAll(['baut aki', 'kabel aki']);
    }

    if (targetKeywords.isEmpty) return [];

    // Find in-stock items matching target keywords not already in cart
    final suggestions = _allItems.where((item) {
      if (cartIds.contains(item.id)) return false;
      if (item.stockDisplay <= 0 && item.stockWarehouse <= 0) return false;

      final name = item.name.toLowerCase();
      final tags = item.tags.map((t) => t.toLowerCase()).join(' ');
      return targetKeywords.any((kw) => name.contains(kw) || tags.contains(kw));
    }).take(4).toList();

    return suggestions;
  }

  /// 💵 AI Smart Cash Suggestions for quick one-tap change calculation
  static List<int> getSmartCashSuggestions(int totalAmount) {
    if (totalAmount <= 0) return [];

    final Set<int> suggestions = {};

    // 1. Exact amount
    suggestions.add(totalAmount);

    // 2. Round up to nearest 5,000 (if not exact)
    if (totalAmount % 5000 != 0) {
      suggestions.add(((totalAmount + 4999) ~/ 5000) * 5000);
    }

    // 3. Round up to nearest 10,000
    if (totalAmount % 10000 != 0) {
      suggestions.add(((totalAmount + 9999) ~/ 10000) * 10000);
    }

    // 4. Round up to nearest 20,000
    if (totalAmount % 20000 != 0) {
      suggestions.add(((totalAmount + 19999) ~/ 20000) * 20000);
    }

    // 5. Round up to nearest 50,000
    if (totalAmount % 50000 != 0) {
      suggestions.add(((totalAmount + 49999) ~/ 50000) * 50000);
    }

    // 6. Round up to nearest 100,000
    if (totalAmount % 100000 != 0) {
      suggestions.add(((totalAmount + 99999) ~/ 100000) * 100000);
    }

    // Standard high denominations
    for (var bill in [50000, 100000, 150000, 200000, 300000, 500000]) {
      if (bill > totalAmount) suggestions.add(bill);
    }

    final list = suggestions.toList()..sort();
    return list.take(5).toList();
  }

  Item? findItemByCode(String code) {
    if (code.isEmpty) return null;
    try {
      return _allItems.firstWhere(
        (item) => item.code.trim().toUpperCase() == code.trim().toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Quantity of [itemId] currently in the cart (0 if absent).
  int quantityInCart(String itemId) {
    for (final ci in _cart) {
      if (ci.id == itemId) return ci.quantity;
    }
    return 0;
  }

  /// Debt needs a named customer; "Pelanggan Umum" can't owe money.
  bool get needsCustomerForDebt => _isDebt && _selectedCustomerId == 'umum';

  /// Adds one unit. Returns false when the item is out of stock or the cart
  /// already holds all available stock.
  bool addToCart(Item item) {
    if (item.stockDisplay <= 0) return false;

    final availableStock = item.stockDisplay;
    final existingIndex = _cart.indexWhere((ci) => ci.id == item.id);

    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity < availableStock) {
        _cart[existingIndex].quantity++;
      } else {
        return false;
      }
    } else {
      if (availableStock <= 0) return false;

      final cartItemRef = Item(
        id: item.id,
        name: item.name,
        code: item.code,
        sellPrice: item.sellPrice,
        buyPrice: item.buyPrice,
        stockDisplay: item.stockDisplay,
        tags: item.tags,
        category: item.category,
        imageUrl: item.imageUrl,
        locationDisplay: item.locationDisplay,
        description: item.description,
      );

      _cart.add(CartItem(item: cartItemRef));
    }
    notifyListeners();
    return true;
  }

  void updateQuantity(String itemId, int delta) {
    final index = _cart.indexWhere((ci) => ci.id == itemId);
    if (index == -1) return;

    final newQty = _cart[index].quantity + delta;
    final maxStock = _cart[index].stockDisplay;

    if (newQty > 0 && newQty <= maxStock) {
      _cart[index].quantity = newQty;
    } else if (newQty <= 0) {
      _cart.removeAt(index);
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cart.removeWhere((ci) => ci.id == itemId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void setCustomer(String id) {
    _selectedCustomerId = id;
    notifyListeners();
  }

  // CHANGED: Returns draft data without saving to DB
  Map<String, dynamic>? calculateTransactionSummary() {
    if (_cart.isEmpty) return null;

    final derivedPaymentMethod = _isDebt ? 'debt' : _paymentType;
    final transactionId = _db
        .collection('transactions')
        .doc()
        .id; // Generate ID

    // Find customer name
    String customerName = "Pelanggan Umum";
    if (_selectedCustomerId != 'umum') {
      final c = _customers.firstWhere(
        (cust) => cust.id == _selectedCustomerId,
        orElse: () => Customer(id: '', name: '', phone: '', address: ''),
      );
      if (c.id.isNotEmpty) customerName = c.name;
    }

    final totalProfit = _cart.fold(
      0,
      (sum, item) => sum + ((item.sellPrice - item.buyPrice) * item.quantity),
    );

    // Prepare Items Map
    final itemsMapList = _cart
        .map(
          (item) => {
            'id': item.id,
            'itemId': item.id,
            'name': item.name,
            'itemName': item.name,
            'quantity': item.quantity,
            'sellPrice': item.sellPrice,
            'buyPrice': item.buyPrice,
            'category': item.category ?? 'Lain-lain',
            'stock': item.stockDisplay,
          },
        )
        .toList();

    return {
      'id': transactionId,
      'customerId': _selectedCustomerId,
      'customerName': customerName,
      'paymentMethod': derivedPaymentMethod,
      'status': derivedPaymentMethod == 'debt' ? 'unpaid' : 'paid',
      'totalAmount': totalAmount,
      'totalProfit': totalProfit,
      'items': itemsMapList,
      'transactionDate': DateTime.now(),
    };
  }

  // CHANGED: Actually writes to DB (Called from Receipt Preview)
  Future<bool> finalizeTransaction(Map<String, dynamic> transactionData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final items = transactionData['items'] as List<dynamic>;

      // Sum quantities per item in case the same item appears twice.
      final Map<String, int> qtyById = {};
      final Map<String, String> nameById = {};
      for (var itemMap in items) {
        final itemId = itemMap['id'] as String;
        qtyById[itemId] = (qtyById[itemId] ?? 0) + (itemMap['quantity'] as int);
        nameById[itemId] = itemMap['name']?.toString() ?? itemId;
      }

      final transactionRef = _db
          .collection('transactions')
          .doc(transactionData['id']);

      // A debt sale records the debt in the same atomic write as the sale.
      // (Writing it afterwards could fail or be cut off, leaving an "unpaid"
      // sale with no debt to collect.)
      final isDebtSale = transactionData['paymentMethod'] == 'debt';
      final customerId = transactionData['customerId'] as String;
      final customerRef = _db.collection('customers').doc(customerId);
      final debtRef = _db.collection('debts').doc();

      // Read + validate + write atomically: if another cashier sells the same
      // item at the same moment, Firestore retries this block with fresh stock,
      // so stock can never go below zero.
      await _db.runTransaction((tx) async {
        // All reads must happen before any write inside a transaction.
        final Map<String, DocumentSnapshot<Map<String, dynamic>>> snaps = {};
        for (final itemId in qtyById.keys) {
          snaps[itemId] = await tx.get(_db.collection('items').doc(itemId));
        }
        if (isDebtSale) {
          if (customerId == 'umum' || !(await tx.get(customerRef)).exists) {
            throw Exception(
              "Pelanggan untuk hutang tidak ditemukan. Pilih pelanggan lagi.",
            );
          }
        }

        for (final entry in qtyById.entries) {
          final snap = snaps[entry.key]!;
          if (!snap.exists) {
            throw Exception("Item ${nameById[entry.key]} tidak ditemukan!");
          }
          final data = snap.data()!;
          final currentStock =
              ((data['stock'] ?? data['qty_display'] ?? data['qty_warehouse'])
                      as num?)
                  ?.toInt() ??
              0;
          if (entry.value > currentStock) {
            throw Exception(
              "Stok ${nameById[entry.key]} tidak cukup! (Tersedia: $currentStock, Diminta: ${entry.value})",
            );
          }
        }

        tx.set(transactionRef, {
          ...transactionData,
          'transactionDate': FieldValue.serverTimestamp(),
        });

        if (isDebtSale) {
          final amount = transactionData['totalAmount'] as int;
          final now = Timestamp.now();
          tx.set(debtRef, {
            'customerId': customerId,
            'customerName': transactionData['customerName'],
            'transactionId': transactionRef.id,
            'totalAmount': amount,
            'remainingAmount': amount,
            'status': 'unpaid',
            'createdAt': now,
            'updatedAt': now,
            'dueDate': null,
            'logs': [],
          });
          tx.update(customerRef, {
            'totalDebt': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Write absolute values (read in this transaction) so both stock
        // fields stay in sync, even for older items without `stock`.
        for (final entry in qtyById.entries) {
          final data = snaps[entry.key]!.data()!;
          final current =
              ((data['stock'] ?? data['qty_display'] ?? data['qty_warehouse'])
                          as num?)
                      ?.toInt() ??
                  0;
          tx.update(_db.collection('items').doc(entry.key), {
            'stock': current - entry.value,
            'qty_display': current - entry.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Clear cart ONLY after success, and start the next sale fresh: a
      // leftover "Hutang" + customer would silently book the next (cash)
      // buyer as debt for the previous customer.
      _cart.clear();
      _isDebt = false;
      _paymentType = 'cash';
      _selectedCustomerId = 'umum';
      await fetchData(); // Refresh local data

      return true;
    } catch (e) {
      print("Finalize Transaction Failed: $e");
      rethrow; // Let UI handle the error message
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
