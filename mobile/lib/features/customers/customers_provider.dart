import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_model.dart';

class CustomersProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('customers').orderBy('name').get();
      _customers = snapshot.docs
          .map((doc) => CustomerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching customers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCustomer(String name, String phone, String address) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.collection('customers').add({
        'name': name,
        'phone': phone,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchCustomers();
      return true;
    } catch (e) {
      print("Error adding customer: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCustomer(
    String id,
    String name,
    String phone,
    String address,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.collection('customers').doc(id).update({
        'name': name,
        'phone': phone,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchCustomers();
      return true;
    } catch (e) {
      print("Error updating customer: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _db.collection('customers').doc(id).delete();
      _customers.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting customer: $e");
      return false;
    }
  }
}
