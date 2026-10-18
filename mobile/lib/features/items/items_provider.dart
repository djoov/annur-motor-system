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

  /// Items already announced as low, so every stock change (each sale)
  /// doesn't re-fire the "stok menipis" notification. null = not loaded yet.
  Set<String>? _announcedLowIds;
  StreamSubscription<QuerySnapshot>? _itemsSubscription;

  ItemsProvider() {
    startListening();
  }

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
        .snapshots()
        .listen(
          (snapshot) {
            _items = snapshot.docs.map((doc) {
              try {
                return Item.fromFirestore(doc);
              } catch (e) {
                print("Error parsing item ${doc.id}: $e");
                return null;
              }
            }).whereType<Item>().toList();

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
    final lowIds = lowStockItems.map((i) => i.id).toSet();

    // First load: one summary. Afterwards: only items that newly ran low.
    final isFirstLoad = _announcedLowIds == null;
    final newlyLow = isFirstLoad
        ? lowStockItems
        : lowStockItems.where((i) => !_announcedLowIds!.contains(i.id)).toList();
    // Restocked items leave the set, so they are announced again next time.
    _announcedLowIds = lowIds;
    if (newlyLow.isEmpty) return;

    final String body;
    if (newlyLow.length == 1) {
      body =
          "Stok ${newlyLow.first.name} menipis (Sisa: ${newlyLow.first.stockDisplay})";
    } else {
      final names = newlyLow.take(3).map((e) => e.name).join(", ");
      final diff = newlyLow.length - 3;
      body = diff > 0
          ? "Stok menipis: $names, dan $diff lainnya."
          : "Stok menipis: $names.";
    }

    NotificationService().showNotification(
      id: 1,
      title: "Peringatan Stok Menipis",
      body: body,
    );
  }

  /// Turns a save failure into a message the cashier can act on, instead of a
  /// generic "gagal disimpan" (which hid duplicate codes and rule denials).
  Exception _saveError(Object e) {
    if (e is DuplicateItemException) return e;
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return Exception(
            "Akun ini tidak diizinkan menyimpan barang. Minta pemilik toko "
            "memastikan akses akun Anda Admin atau Staff di Kelola Pengguna.",
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return Exception(
            "Tidak tersambung ke server. Periksa internet lalu coba lagi.",
          );
        case 'not-found':
          return Exception("Barang ini sudah dihapus dari daftar.");
      }
      return Exception("Barang gagal disimpan (${e.code}). Coba lagi.");
    }
    return Exception("Barang gagal disimpan. Coba lagi.");
  }

  Future<bool> addItem(
    String name,
    String code,
    int sellPrice,
    int buyPrice,
    int stockDisplay,
    List<String> tags,
    String category,
    String? imageUrl,
    String? locationDisplay,
    String? description,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

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
        'stock': stockDisplay,
        'qty_display': stockDisplay,
        'tags': tags,
        'category': category,
        'imageUrl': imageUrl,
        'location_display': locationDisplay,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchItems();
      return true;
    } catch (e) {
      print("Error adding item: $e");
      throw _saveError(e);
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
    List<String> tags,
    String category,
    String? imageUrl,
    String? locationDisplay,
    String? description, {
    int? originalStock,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

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
        // Only write stock when the user changed it in the form. Otherwise
        // editing a price would reset stock to the value shown when the form
        // opened, undoing any sale made in the meantime.
        if (originalStock == null || stockDisplay != originalStock) ...{
          'stock': stockDisplay,
          'qty_display': stockDisplay,
        },
        'tags': tags,
        'category': category,
        'imageUrl': imageUrl ?? '',
        'location_display': locationDisplay,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchItems();
      return true;
    } catch (e) {
      print("Error updating item: $e");
      throw _saveError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStock(String id, int newStock) async {
    try {
      await _db.collection('items').doc(id).update({
        'stock': newStock,
        'qty_display': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchItems();
      return true;
    } catch (e) {
      print("Error updating stock: $e");
      return false;
    }
  }

  /// Quick stock adjustment - updates stock by delta value
  Future<bool> quickUpdateStock(String id, String location, int delta) async {
    try {
      final index = _items.indexWhere((i) => i.id == id);
      if (index == -1) return false;

      // Read the current stock inside a transaction so a sale made a moment
      // ago isn't overwritten by the (possibly stale) value on screen.
      final ref = _db.collection('items').doc(id);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception("Barang tidak ditemukan");
        final data = snap.data()!;
        final current =
            ((data['stock'] ?? data['qty_display'] ?? data['qty_warehouse'])
                        as num?)
                    ?.toInt() ??
                0;
        final newStock = current + delta < 0 ? 0 : current + delta;
        tx.update(ref, {
          'stock': newStock,
          'qty_display': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      await fetchItems();
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

      // 🌟 Auto-register any new categories found in CSV to the 'categories' collection
      try {
        final uniqueCategories = itemsData
            .map((e) => e['category']?.toString().trim())
            .where((c) => c != null && c.isNotEmpty && c != 'Umum')
            .toSet();

        if (uniqueCategories.isNotEmpty) {
          final existingCatsSnap = await _db.collection('categories').get();
          final existingCatNames = existingCatsSnap.docs
              .map((d) => (d.data()['name'] ?? '').toString().trim().toLowerCase())
              .toSet();

          final catBatch = _db.batch();
          bool hasNewCats = false;

          for (var cat in uniqueCategories) {
            if (cat != null && !existingCatNames.contains(cat.toLowerCase())) {
              final newCatRef = _db.collection('categories').doc();
              catBatch.set(newCatRef, {
                'name': cat,
                'createdAt': FieldValue.serverTimestamp(),
              });
              existingCatNames.add(cat.toLowerCase());
              hasNewCats = true;
            }
          }

          if (hasNewCats) {
            await catBatch.commit();
          }
        }
      } catch (catError) {
        print("Warning: Auto-registering categories skipped: $catError");
      }

      int parseInt(dynamic val) {
        if (val == null) return 0;
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) {
          final clean = val.replaceAll(RegExp(r'[^0-9\-]'), '');
          return int.tryParse(clean) ??
              double.tryParse(clean)?.toInt() ??
              0;
        }
        return 0;
      }

      List<void Function(WriteBatch batch)> batchOperations = [];

      for (var data in itemsData) {
        final code = data['code']?.toString().trim().toUpperCase() ?? '';
        final name = data['name']?.toString().trim() ?? '';
        final sellPrice = parseInt(data['sellPrice']);
        final buyPrice = parseInt(data['buyPrice']);
        final stock = parseInt(data['stock'] ?? data['qty_display'] ?? data['qty_warehouse']);
        final tags =
            (data['tags'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        final category = data['category']?.toString().trim() ?? 'Umum';
        final locationDisplay = (data['location_display'] ?? data['location'])?.toString().trim();
        final description = data['description']?.toString().trim();

        if (code.isEmpty || name.isEmpty) continue;

        if (existingItemsMap.containsKey(code)) {
          final existingItem = existingItemsMap[code]!;
          final docRef = _db.collection('items').doc(existingItem.id);

          Map<String, dynamic> updates = {
            'name': name,
            'sellPrice': sellPrice > 0 ? sellPrice : existingItem.sellPrice,
            'buyPrice': buyPrice > 0 ? buyPrice : existingItem.buyPrice,
            'category': category.isNotEmpty ? category : existingItem.category,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (locationDisplay != null && locationDisplay.isNotEmpty) {
            updates['location_display'] = locationDisplay;
          }
          if (description != null && description.isNotEmpty) {
            updates['description'] = description;
          }
          if (tags.isNotEmpty) {
            updates['tags'] = tags;
          }

          if (isRestockMode) {
            if (stock > 0) {
              updates['stock'] = FieldValue.increment(stock);
              updates['qty_display'] = FieldValue.increment(stock);
            }
          } else {
            updates['stock'] = stock;
            updates['qty_display'] = stock;
          }

          batchOperations.add((batch) => batch.update(docRef, updates));
          updated++;
        } else {
          final docRef = _db.collection('items').doc();
          final newItemData = {
            'name': name,
            'code': code,
            'sellPrice': sellPrice,
            'buyPrice': buyPrice,
            'stock': stock,
            'qty_display': stock,
            'tags': tags,
            'category': category.isNotEmpty ? category : 'Umum',
            'location_display': locationDisplay ?? '',
            'description': description ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          };

          batchOperations.add((batch) => batch.set(docRef, newItemData));
          created++;
        }
      }

      // Commit in chunks of 400 operations (Firestore batch limit is 500)
      const chunkSize = 400;
      for (var i = 0; i < batchOperations.length; i += chunkSize) {
        final end = (i + chunkSize < batchOperations.length)
            ? i + chunkSize
            : batchOperations.length;
        final chunk = batchOperations.sublist(i, end);
        final batch = _db.batch();
        for (var op in chunk) {
          op(batch);
        }
        await batch.commit();
      }

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
