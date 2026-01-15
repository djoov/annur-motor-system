import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';
import 'stock_request_model.dart';
import '../auth/auth_provider.dart';

class StockRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AuthProvider? _authProvider;

  List<StockRequest> _requests = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _requestSubscription;

  List<StockRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  // Pending count for Admin badge
  int get pendingCount => _requests.where((r) => r.status == 'pending').length;

  StockRequestProvider();

  void update(AuthProvider auth) {
    _authProvider = auth;
    _init();
  }

  void _init() {
    if (_authProvider == null) return;

    // If user is Admin, listen to ALL pending requests for notifications & badge
    if (_authProvider!.isAdmin) {
      _listenForNotifications();
      fetchRequests(); // Auto-fetch for badge count
    } else {
      // Staff: Listen for status changes on their own requests
      _listenForStaffFeedback();
    }
  }

  // --- Staff Feedback Listener ---
  StreamSubscription<QuerySnapshot>? _staffFeedbackSubscription;

  void _listenForStaffFeedback() {
    if (_authProvider?.user == null) return;

    _staffFeedbackSubscription?.cancel();

    // Listen to MY requests for status changes
    _staffFeedbackSubscription = _db
        .collection('stock_requests')
        .where('requesterId', isEqualTo: _authProvider!.user!.uid)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final data = change.doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? '';
              final itemName = data['itemName'] ?? 'Barang';
              final qty = data['requestQty'] ?? 0;

              if (status == 'approved') {
                NotificationService().showNotification(
                  id: change.doc.id.hashCode,
                  title: 'Permintaan Disetujui ✅',
                  body: 'Request $qty x $itemName telah di-approve!',
                );
              } else if (status == 'rejected') {
                NotificationService().showNotification(
                  id: change.doc.id.hashCode,
                  title: 'Permintaan Ditolak ❌',
                  body: 'Request $qty x $itemName ditolak oleh Admin.',
                );
              }
            }
          }
        });
  }

  // --- Realtime Listeners ---

  void fetchRequests() {
    _isLoading = true;
    notifyListeners();

    _requestSubscription?.cancel();

    Query query = _db
        .collection('stock_requests')
        .orderBy('createdAt', descending: true);

    // If Staff, only show my requests (optional, or show all but disable actions? Requirement says "Staff creates, Admin approves")
    // Usually staff wants to see status of THEIR requests.
    if (_authProvider != null &&
        !_authProvider!.isAdmin &&
        _authProvider!.user != null) {
      query = query.where('requesterId', isEqualTo: _authProvider!.user!.uid);
    }

    _requestSubscription = query.snapshots().listen(
      (snapshot) {
        _requests = snapshot.docs
            .map((doc) => StockRequest.fromFirestore(doc))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        print("Error fetching stock requests: $e");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Separate listener specifically for notifications (Admin only)
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  void _listenForNotifications() {
    _notificationSubscription?.cancel();

    // Listen for NEW pending requests added recently
    // We use a timestamp check or just listen to 'added' changes.
    // To avoid spamming on restart, ideally we'd filter by timestamp > now, but Firestore requires an index for that often.
    // Simpler approach for "popup hp saat itu juga" (while app runs):
    // Listen to changes. If type is 'added' and source is not local (has ID), show notif.

    _notificationSubscription = _db
        .collection('stock_requests')
        .where('status', isEqualTo: 'pending')
        // .where('createdAt', isGreaterThan: Timestamp.now()) // This is tricky on restart.
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              // Verify it's not a historical fetch (check if it's new)
              // doc.metadata.isFromCache?
              // Or check timestamp logic.
              // For MVP: simple change listener.

              final data = change.doc.data() as Map<String, dynamic>;
              final name = data['itemName'] ?? 'Unknown Item';
              final qty = data['requestQty'] ?? 0;
              final requester = data['requesterName'] ?? 'Staff';

              // Avoid notifying for own requests if Admin tests it
              if (data['requesterId'] != _authProvider?.user?.uid) {
                NotificationService().showNotification(
                  id: change.doc.id.hashCode,
                  title: 'Permintaan Stok Baru 📦',
                  body: '$requester meminta $qty x $name',
                );
              }
            }
          }
        });
  }

  // --- Actions ---

  Future<bool> createRequest({
    required String itemId,
    required String itemName,
    String? itemImage,
    required int quantity,
  }) async {
    try {
      final user = _authProvider?.user;
      final userModel = _authProvider?.userModel;

      if (user == null) return false;

      final newRequest = StockRequest(
        id: '', // Placeholder
        itemId: itemId,
        itemName: itemName,
        itemImage: itemImage,
        requestQty: quantity,
        status: 'pending',
        requesterId: user.uid,
        requesterName: userModel?.name ?? user.displayName ?? 'Staff',
        createdAt: DateTime.now(),
      );

      await _db.collection('stock_requests').add(newRequest.toMap());
      return true;
    } catch (e) {
      print("Error creating stock request: $e");
      return false;
    }
  }

  Future<bool> approveRequest(StockRequest request) async {
    try {
      final user = _authProvider?.user;
      final userModel = _authProvider?.userModel;
      if (user == null || _authProvider?.isAdmin != true) return false;

      // 1. Run Transaction
      await _db.runTransaction((transaction) async {
        DocumentReference itemRef = _db.collection('items').doc(request.itemId);
        DocumentReference requestRef = _db
            .collection('stock_requests')
            .doc(request.id);

        DocumentSnapshot itemSnapshot = await transaction.get(itemRef);
        if (!itemSnapshot.exists) {
          throw Exception("Item not found");
        }

        final itemData = itemSnapshot.data() as Map<String, dynamic>;
        final currentWarehouse =
            (itemData['qty_warehouse'] as num?)?.toInt() ?? 0;
        final currentDisplay = (itemData['qty_display'] as num?)?.toInt() ?? 0;

        if (currentWarehouse < request.requestQty) {
          throw Exception("Stok Gudang tidak cukup! (Sisa: $currentWarehouse)");
        }

        // Move Stock
        transaction.update(itemRef, {
          'qty_warehouse': currentWarehouse - request.requestQty,
          'qty_display': currentDisplay + request.requestQty,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update Request Status
        transaction.update(requestRef, {
          'status': 'approved',
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolverId': user.uid,
          'resolverName': userModel?.name ?? 'Admin',
        });

        // Optional: Add to Transaction History (Internal Movement) -- Skipping for now to keep simple
      });

      return true;
    } catch (e) {
      print("Error approving request: $e");
      // Could show snackbar error here if we had context, but returning false works
      rethrow; // Rethrow to let UI handle error message
    }
  }

  Future<bool> rejectRequest(StockRequest request) async {
    try {
      final user = _authProvider?.user;
      final userModel = _authProvider?.userModel;

      await _db.collection('stock_requests').doc(request.id).update({
        'status': 'rejected',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolverId': user?.uid,
        'resolverName': userModel?.name ?? 'Admin',
      });
      return true;
    } catch (e) {
      print("Error rejecting request: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _notificationSubscription?.cancel();
    _staffFeedbackSubscription?.cancel();
    super.dispose();
  }
}
