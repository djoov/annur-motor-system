import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_model.dart';

class CategoriesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  CategoriesProvider() {
    fetchCategories();
  }

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('categories').get();
      _categories = snapshot.docs.map((doc) {
        try {
          return CategoryModel.fromFirestore(doc);
        } catch (e) {
          print("Error parsing category ${doc.id}: $e");
          return null;
        }
      }).whereType<CategoryModel>().toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.collection('categories').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchCategories();
      return true;
    } catch (e) {
      print("Error adding category: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory(String id, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db.collection('categories').doc(id).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchCategories();
      return true;
    } catch (e) {
      print("Error updating category: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _db.collection('categories').doc(id).delete();
      _categories.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting category: $e");
      return false;
    }
  }
}
