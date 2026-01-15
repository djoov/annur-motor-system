import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db.collection('users').get();
      _users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserRole(String uid, String newRole) async {
    try {
      await _db.collection('users').doc(uid).update({'role': newRole});
      // Update local state
      final index = _users.indexWhere((u) => u.id == uid);
      if (index != -1) {
        _users[index] = UserModel(
          id: uid,
          email: _users[index].email,
          role: newRole,
          name: _users[index].name,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      print("Error updating role: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      // Note: This only deletes the Firestore doc.
      // Deleting Authentication User requires Admin SDK or Cloud Functions, or re-authentication.
      // For MVP, we just remove access (by deleting role doc).
      // AuthProvider checks doc existence -> if not exists, defaults to Staff (or should create?).
      // Better strategy: Mark as 'inactive' or keep doc but role 'banned'?
      // Let's just delete the doc. AuthProvider will fallback to 'staff' if not found, effectively demoting them but not banning.
      // To Ban: Update role to 'banned'.
      await _db.collection('users').doc(uid).delete();
      _users.removeWhere((u) => u.id == uid);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }
}
