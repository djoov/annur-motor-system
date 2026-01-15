import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = true;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  // Helper for UI Masking
  bool get isAdmin => _userModel?.role == 'admin';

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserRole(user.uid);
      } else {
        _userModel = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      } else {
        // Fallback if user doc doesn't exist (e.g. first login or manual auth)
        // For MVP, if it matches Main Admin Email/Dev, make admin?
        // Or just default to Staff (safe).
        // But for development, let's create a doc if missing?
        // Let's just set as generic staff for now.
        _userModel = UserModel(
          id: uid,
          email: _user?.email ?? '',
          role: 'staff',
          name: _user?.displayName ?? 'User',
        );
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Wait for role fetch manually to ensure UI has role before navigating
      if (cred.user != null) {
        await _fetchUserRole(cred.user!.uid);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      // 1. Create Auth User
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // 2. Update Display Name
        await cred.user!.updateDisplayName(name);

        // 3. Create Firestore Doc
        final newUser = UserModel(
          id: cred.user!.uid,
          email: email,
          name: name,
          role: 'staff',
        );

        await _db.collection('users').doc(cred.user!.uid).set(newUser.toMap());

        // 4. Set local state
        _user = cred.user;
        _userModel = newUser;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> becomeAdmin() async {
    if (_user == null) return;
    try {
      await _db.collection('users').doc(_user!.uid).set({
        'email': _user!.email,
        'name': _user!.displayName ?? 'Admin User',
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _fetchUserRole(_user!.uid);
      notifyListeners();
    } catch (e) {
      print("Error becoming admin: $e");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }
}
