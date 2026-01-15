import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/pos_models.dart';

class PosProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  List<Customer> _customers = [];
  final List<CartItem> _cart = [];
  String _selectedCustomerId = 'umum';
  bool _isLoading = false;

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

  // PosProvider constructor removed to prevent immediate notifyListeners
  // Call fetchData() from UI instead.

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final itemsSnapshot = await _db.collection('items').get();
      _allItems = itemsSnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();
      _filteredItems = List.from(_allItems);

      // Extract unique categories
      final catSet = _allItems.map((e) => e.category ?? 'Umum').toSet();
      _categories = ["Semua", ...catSet.toList()..sort()];

      final customersSnapshot = await _db.collection('customers').get();
      _customers = customersSnapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  bool _isWorkshopMode = false;

  bool get isWorkshopMode => _isWorkshopMode;

  void setWorkshopMode(bool value) {
    _isWorkshopMode = value;
    // Update prices of existing cart items?
    // SRS implies mode is a toggle. If toggled, all current cart items should probably update?
    // Or is it per transaction?
    // Let's assume it updates the current view and subsequent adds.
    // For simplicity, let's clear cart or ask to clear, OR just update cart items.
    // Let's update all cart items prices.
    for (var item in _cart) {
      if (item.category != 'Jasa') {
        // Don't change service items if any
        // This is tricky because CartItem extends Item and sellPrice is final.
        // We might need to replace items in cart.
      }
    }
    // For MVP: Clearing cart might be safer, but annoying.
    // Better: Re-map the cart with new prices.

    final newCart = _cart.map((ci) {
      final newItem = Item(
        id: ci.id,
        name: ci.name,
        code: ci.code,
        sellPrice: value && ci.priceWorkshop > 0
            ? ci.priceWorkshop
            : _allItems.firstWhere((i) => i.id == ci.id).sellPrice,
        buyPrice: ci.buyPrice,
        stockDisplay: ci.stockDisplay,
        stockWarehouse: ci.stockWarehouse,
        priceWorkshop: ci.priceWorkshop,
        tags: ci.tags,
        category: ci.category,
        imageUrl: ci.imageUrl,
      );
      return CartItem(item: newItem, quantity: ci.quantity);
    }).toList();

    _cart.clear();
    _cart.addAll(newCart);

    notifyListeners();
  }

  // ... [search logic update]
  void _applyFilters() {
    List<Item> temp = _allItems;

    if (_selectedCategory != "Semua") {
      temp = temp.where((item) => item.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      temp = temp.where((item) {
        final matchesName = item.name.toLowerCase().contains(lower);
        final matchesCode = item.code.toLowerCase().contains(lower);
        final matchesTags = item.tags.any(
          (tag) => tag.toLowerCase().contains(lower),
        );
        return matchesName || matchesCode || matchesTags;
      }).toList();
    }

    _filteredItems = temp;
    notifyListeners();
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

  void addToCart(Item item) {
    if (item.stockDisplay <= 0) {
      // Simple logic for MVP: If display empty, check warehouse
      if (item.stockWarehouse > 0) {
        // ideally show notification "Ambil di Gudang!"
      } else {
        return;
      }
    }

    // Check strict stock availability
    final availableStock = item.stockDisplay + item.stockWarehouse;

    final existingIndex = _cart.indexWhere((ci) => ci.id == item.id);
    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity < availableStock) {
        _cart[existingIndex].quantity++;
      } else {
        // Show notification or just return
        return;
      }
    } else {
      if (availableStock <= 0) return; // Don't add if 0 stock

      // Use correct price based on mode
      final price = _isWorkshopMode && item.priceWorkshop > 0
          ? item.priceWorkshop
          : item.sellPrice;

      // Create a temporary item with the active price
      final cartItemRef = Item(
        id: item.id,
        name: item.name,
        code: item.code,
        sellPrice: price,
        buyPrice: item.buyPrice,
        stockDisplay: item.stockDisplay,
        stockWarehouse: item.stockWarehouse,
        priceWorkshop: item.priceWorkshop,
        tags: item.tags,
        category: item.category,
        imageUrl: item.imageUrl,
      );

      _cart.add(CartItem(item: cartItemRef));
    }
    notifyListeners();
  }

  void updateQuantity(String itemId, int delta) {
    final index = _cart.indexWhere((ci) => ci.id == itemId);
    if (index == -1) return;

    final newQty = _cart[index].quantity + delta;
    // Allow selling up to Display + Warehouse logic
    // For now, strict check against total stock
    final maxStock = _cart[index].stockDisplay + _cart[index].stockWarehouse;

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
        orElse: () => Customer(id: '', name: ''),
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
            'itemId': item.id, // For consistency
            'name': item.name,
            'itemName': item.name,
            'quantity': item.quantity,
            'sellPrice': item.sellPrice,
            'buyPrice': item.buyPrice,
            'category': item.category ?? 'Lain-lain',
            'stockDisplay': item.stockDisplay, // Needed for finalization logic
            'stockWarehouse': item.stockWarehouse,
            'priceWorkshop': item.priceWorkshop,
          },
        )
        .toList();

    return {
      'id': transactionId,
      'customerId': _selectedCustomerId, // Needed for finalization
      'customerName': customerName,
      'paymentMethod': derivedPaymentMethod,
      'status': derivedPaymentMethod == 'debt' ? 'unpaid' : 'paid',
      'totalAmount': totalAmount,
      'totalProfit': totalProfit,
      'items': itemsMapList,
      'transactionDate': DateTime.now(), // Visual only
    };
  }

  // CHANGED: Actually writes to DB (Called from Receipt Preview)
  Future<bool> finalizeTransaction(Map<String, dynamic> transactionData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final items = transactionData['items'] as List<dynamic>;

      // --- STEP 1: Fetch and validate all stock in one pass ---
      final Map<String, Map<String, int>> stockCache = {};

      for (var itemMap in items) {
        final itemId = itemMap['id'];
        final quantity = itemMap['quantity'] as int;

        // Get latest stock from Firestore
        final itemDoc = await _db.collection('items').doc(itemId).get();
        if (!itemDoc.exists) {
          throw Exception("Item ${itemMap['name']} tidak ditemukan!");
        }

        final data = itemDoc.data()!;
        final currentDisplay = (data['qty_display'] as num?)?.toInt() ?? 0;
        final currentWarehouse = (data['qty_warehouse'] as num?)?.toInt() ?? 0;
        final totalAvailable = currentDisplay + currentWarehouse;

        if (quantity > totalAvailable) {
          throw Exception(
            "Stok ${itemMap['name']} tidak cukup! (Tersedia: $totalAvailable, Diminta: $quantity)",
          );
        }

        // Cache for later use
        stockCache[itemId] = {
          'display': currentDisplay,
          'warehouse': currentWarehouse,
        };
      }

      // --- STEP 2: Commit Transaction ---
      final batch = _db.batch();
      final transactionRef = _db
          .collection('transactions')
          .doc(transactionData['id']);

      // Create Transaction
      batch.set(transactionRef, {
        ...transactionData,
        'transactionDate': FieldValue.serverTimestamp(),
      });

      // Update Stock (Smart deduction: Display first, then Warehouse)
      for (var itemMap in items) {
        final itemId = itemMap['id'];
        final quantity = itemMap['quantity'] as int;

        // Use cached values
        final stock = stockCache[itemId]!;
        final currentDisplay = stock['display']!;

        int deductFromDisplay = 0;
        int deductFromWarehouse = 0;

        if (currentDisplay >= quantity) {
          deductFromDisplay = quantity;
        } else {
          deductFromDisplay = currentDisplay;
          deductFromWarehouse = quantity - currentDisplay;
        }

        final itemRef = _db.collection('items').doc(itemId);

        batch.update(itemRef, {
          'qty_display': FieldValue.increment(-deductFromDisplay),
          'qty_warehouse': FieldValue.increment(-deductFromWarehouse),
          'stock': FieldValue.increment(-deductFromDisplay),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Clear cart ONLY after success
      _cart.clear();
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
