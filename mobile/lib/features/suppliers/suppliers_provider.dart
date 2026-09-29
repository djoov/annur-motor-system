import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'supplier_model.dart';

class SuppliersProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;

  SuppliersProvider() {
    fetchSuppliers();
  }

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  Future<void> fetchSuppliers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('suppliers').get();
      _suppliers = snapshot.docs.map((doc) {
        try {
          return SupplierModel.fromFirestore(doc);
        } catch (e) {
          print("Error parsing supplier ${doc.id}: $e");
          return null;
        }
      }).whereType<SupplierModel>().toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      print("Error fetching suppliers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(
    String name,
    String phone,
    String address,
    String contactPerson,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.collection('suppliers').add({
        'name': name,
        'phone': phone,
        'address': address,
        'contactPerson': contactPerson,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchSuppliers();
      return true;
    } catch (e) {
      print("Error adding supplier: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSupplier(
    String id,
    String name,
    String phone,
    String address,
    String contactPerson,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.collection('suppliers').doc(id).update({
        'name': name,
        'phone': phone,
        'address': address,
        'contactPerson': contactPerson,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchSuppliers();
      return true;
    } catch (e) {
      print("Error updating supplier: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      await _db.collection('suppliers').doc(id).delete();
      _suppliers.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting supplier: $e");
      return false;
    }
  }
}
