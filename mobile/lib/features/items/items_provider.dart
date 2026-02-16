import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../pos/models/pos_models.dart';
import '../../core/services/notification_service.dart';
import 'exceptions.dart';

class ItemsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Item> _items = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _itemsSubscription;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;

  // Low Stock Getters
  List<Item> get lowStockDisplayItems =>
      _items.where((i) => i.stockDisplay <= 5).toList();

  List<Item> get lowStockWarehouseItems =>
      _items.where((i) => i.stockWarehouse <= 5).toList();

  // Find Item by Code
  Item? findByCode(String code) {
    try {
      final normalized = code.trim().toUpperCase();
      return _items.firstWhere((item) => item.code.toUpperCase() == normalized);
    } catch (e) {
      return null;
    }
  }

  /// Start listening to real-time updates from Firestore
  void startListening() {
    _isLoading = true;
    notifyListeners();

    _itemsSubscription?.cancel(); // Cancel any existing subscription
    _itemsSubscription = _db
        .collection('items')
        .orderBy('name')
        .snapshots()
        .listen(
          (snapshot) {
            _items = snapshot.docs
                .map((doc) => Item.fromFirestore(doc))
                .toList();
            _isLoading = false;
            _checkLowStock();
            notifyListeners();
          },
          onError: (e) {
            print("Error listening to items: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Stop listening (call on dispose)
  void stopListening() {
    _itemsSubscription?.cancel();
    _itemsSubscription = null;
  }

  /// Legacy fetch for backward compatibility (now uses startListening internally)
  Future<void> fetchItems() async {
    if (_itemsSubscription == null) {
      startListening();
    }
    // Wait a bit for initial data
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _checkLowStock() {
    final lowStockItems = _items.where((i) => i.stockDisplay <= 5).toList();
    if (lowStockItems.isNotEmpty) {
      // Build detailed message
      String body = "";
      if (lowStockItems.length == 1) {
        body =
            "Stok ${lowStockItems.first.name} menipis (Sisa: ${lowStockItems.first.stockDisplay})";
      } else {
        final names = lowStockItems.take(3).map((e) => e.name).join(", ");
        final diff = lowStockItems.length - 3;
        if (diff > 0) {
          body = "Stok menipis: $names, dan $diff lainnya.";
        } else {
          body = "Stok menipis: $names.";
        }
      }

      // Notification
      NotificationService().showNotification(
        id: 1,
        title: "Peringatan Stok Menipis",
        body: body,
      );
    }
  }

  Future<bool> addItem(
    String name,
    String code,
    int sellPrice,
    int buyPrice,
    int stockDisplay,
    int stockWarehouse,
    int priceWorkshop,
    List<String> tags,
    String category,
    String? imageUrl,
    String? locationDisplay,
    String? locationWarehouse,
    String? description,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check for duplicates
      final normalizedCode = code.trim().toUpperCase();
      final exists = _items.any((i) => i.code.toUpperCase() == normalizedCode);
      if (exists) {
        throw DuplicateItemException(
          "Kode Barang '$normalizedCode' sudah digunakan oleh barang lain.",
        );
      }

      await _db.collection('items').add({
        'name': name,
        'code': normalizedCode,
        'sellPrice': sellPrice,
        'buyPrice': buyPrice,
        'qty_display': stockDisplay,
        'stock': stockDisplay, // Legacy sync
        'qty_warehouse': stockWarehouse,
        'price_workshop': priceWorkshop,
        'tags': tags,
        'category': category,
        'imageUrl': imageUrl,
        'location_display': locationDisplay,
        'location_warehouse': locationWarehouse,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchItems(); // Refresh list
      return true;
    } catch (e) {
      print("Error adding item: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateItem(
    String id,
    String name,
    String code,
    int sellPrice,
    int buyPrice,
    int stockDisplay,
    int stockWarehouse,
    int priceWorkshop,
    List<String> tags,
    String category,
    String? imageUrl,
    String? locationDisplay,
    String? locationWarehouse,
    String? description,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check for duplicates if code changed
      // We need to check if ANY OTHER item has this code
      // Since we don't have the full list in memory reliably updated (or we do?),
      // Best to rely on _items if it's synced, or query DB.
      // Since _items is loaded, we can use it.
      final normalizedCode = code.trim().toUpperCase();
      final existingParams = _items.firstWhere(
        (i) => i.id == id,
        orElse: () => Item(
          id: '',
          name: '',
          code: '',
          sellPrice: 0,
          buyPrice: 0,
          stockDisplay: 0,
          stockWarehouse: 0,
          tags: [],
          category: '',
        ),
      );

      if (existingParams.code.toUpperCase() != normalizedCode) {
        final isDuplicate = _items.any(
          (i) => i.id != id && i.code.toUpperCase() == normalizedCode,
        );
        if (isDuplicate) {
          throw DuplicateItemException(
            "Kode '$normalizedCode' sudah dipakai barang lain.",
          );
        }
      }

      await _db.collection('items').doc(id).update({
        'name': name,
        'code': normalizedCode,
        'sellPrice': sellPrice,
        'buyPrice': buyPrice,
        'qty_display': stockDisplay,
        'stock': stockDisplay, // Legacy sync
        'qty_warehouse': stockWarehouse,
        'price_workshop': priceWorkshop,
        'tags': tags,
        'category': category,
        'imageUrl': imageUrl ?? '', // Always update, empty string if deleted
        'location_display': locationDisplay,
        'location_warehouse': locationWarehouse,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchItems(); // Refresh list
      return true;
    } catch (e) {
      print("Error updating item: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStock(String id, int newStock) async {
    try {
      // Optimistic update
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        // We can't easily modify the immutable Item object in place without copying
        // But for UI responsiveness, we rely on fetchItems or just wait for it.
        // Let's just do the DB call.
      }

      await _db.collection('items').doc(id).update({
        'qty_display': newStock,
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchItems(); // Refresh to ensure consistency
      return true;
    } catch (e) {
      print("Error updating stock: $e");
      return false;
    }
  }

  /// Quick stock adjustment - updates stock by delta value
  /// [location] can be 'display' or 'warehouse'
  /// [delta] is the change amount (positive to add, negative to subtract)
  Future<bool> quickUpdateStock(String id, String location, int delta) async {
    try {
      final index = _items.indexWhere((i) => i.id == id);
      if (index == -1) return false;

      final item = _items[index];
      int currentStock = location == 'display'
          ? item.stockDisplay
          : item.stockWarehouse;
      int newStock = currentStock + delta;
      if (newStock < 0) newStock = 0; // Don't allow negative stock

      final fieldName = location == 'display' ? 'qty_display' : 'qty_warehouse';

      await _db.collection('items').doc(id).update({
        fieldName: newStock,
        if (location == 'display') 'stock': newStock, // Legacy field
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchItems(); // Refresh to get updated data
      return true;
    } catch (e) {
      print("Error quick updating stock: $e");
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _db.collection('items').doc(id).delete();
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting item: $e");
      return false;
    }
  }

  Future<Map<String, int>> bulkUpsertItems(
    List<Map<String, dynamic>> itemsData, {
    bool isRestockMode = true,
  }) async {
    int created = 0;
    int updated = 0;
    _isLoading = true;
    notifyListeners();

    try {
      if (_items.isEmpty) {
        await fetchItems();
      }

      final Map<String, Item> existingItemsMap = {
        for (var item in _items) item.code.trim().toUpperCase(): item,
      };

      final batch = _db.batch();

      for (var data in itemsData) {
        final code = data['code'].toString().trim().toUpperCase();
        final name = data['name'].toString().trim();
        final sellPrice = int.tryParse(data['sellPrice'].toString()) ?? 0;
        final buyPrice = int.tryParse(data['buyPrice'].toString()) ?? 0;
        final priceWorkshop =
            int.tryParse(data['price_workshop'].toString()) ?? 0;
        final qtyDisplay = int.tryParse(data['qty_display'].toString()) ?? 0;
        final qtyWarehouse =
            int.tryParse(data['qty_warehouse'].toString()) ?? 0;
        final tags =
            (data['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final category = data['category'].toString().trim();

        final locationDisplay = data['location_display']?.toString().trim();
        final locationWarehouse = data['location_warehouse']?.toString().trim();
        final description = data['description']?.toString().trim();

        if (code.isEmpty || name.isEmpty) continue;

        if (existingItemsMap.containsKey(code)) {
          // UPDATE Existing
          final existingItem = existingItemsMap[code]!;
          final docRef = _db.collection('items').doc(existingItem.id);

          Map<String, dynamic> updates = {
            'name': name,
            // Always update prices/details if valid data is present (Assume CSV is latest)
            'sellPrice': sellPrice > 0 ? sellPrice : existingItem.sellPrice,
            'buyPrice': buyPrice > 0 ? buyPrice : existingItem.buyPrice,
            'price_workshop': priceWorkshop > 0
                ? priceWorkshop
                : existingItem.priceWorkshop,
            'category': category.isNotEmpty ? category : existingItem.category,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (locationDisplay != null && locationDisplay.isNotEmpty) {
            updates['location_display'] = locationDisplay;
          }

          if (locationWarehouse != null && locationWarehouse.isNotEmpty) {
            updates['location_warehouse'] = locationWarehouse;
          }

          if (description != null && description.isNotEmpty) {
            updates['description'] = description;
          }

          if (tags.isNotEmpty) {
            updates['tags'] = tags;
          }

          // STOCK LOGIC: The Core Difference
          if (isRestockMode) {
            // RESTOCK: Increment existing stock
            if (qtyDisplay > 0) {
              updates['qty_display'] = FieldValue.increment(qtyDisplay);
              updates['stock'] = FieldValue.increment(qtyDisplay); // Legacy
            }
            if (qtyWarehouse > 0) {
              updates['qty_warehouse'] = FieldValue.increment(qtyWarehouse);
            }
          } else {
            // OVERWRITE: Replace with CSV value
            // We only overwrite if the CSV value is >= 0.
            // If CSV value is 0, it means 0 stock.
            // Users should be careful. To keep existing, they should omit column or use current value.
            // Assumption: If they export then import, the value IS the current value or edited value.
            updates['qty_display'] = qtyDisplay;
            updates['stock'] = qtyDisplay; // Legacy
            updates['qty_warehouse'] = qtyWarehouse;
          }

          batch.update(docRef, updates);
          updated++;
        } else {
          // CREATE New (Always Use Values as is)
          final docRef = _db.collection('items').doc();
          batch.set(docRef, {
            'name': name,
            'code': code,
            'sellPrice': sellPrice,
            'buyPrice': buyPrice,
            'price_workshop': priceWorkshop,
            'qty_display': qtyDisplay,
            'qty_warehouse': qtyWarehouse,
            'stock': qtyDisplay,
            'tags': tags,
            'category': category.isNotEmpty ? category : 'Umum',
            'location_display': locationDisplay,
            'location_warehouse': locationWarehouse,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
          });
          created++;
        }
      }

      await batch.commit();
      await fetchItems(); // Refresh UI
      return {'created': created, 'updated': updated};
    } catch (e) {
      print("Error bulk upserting: $e");
      return {'created': 0, 'updated': 0};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
