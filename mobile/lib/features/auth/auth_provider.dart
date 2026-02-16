import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io' show Platform;
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
        // Don't await this, let it run in background to avoid blocking startup
        updateUserActivity();
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

  /// Update user activity in Firestore (called on login and periodically)
  Future<void> updateUserActivity() async {
    if (_user == null) return;

    try {
      String deviceInfo = 'Unknown Device';
      String devicePlatform = 'Unknown';
      String? locationName;

      if (kIsWeb) {
        devicePlatform = 'Web';
        deviceInfo = 'Browser';
      } else {
        if (Platform.isAndroid) {
          devicePlatform = 'Android';
          deviceInfo = 'Android Device';
        } else if (Platform.isIOS) {
          devicePlatform = 'iOS';
          deviceInfo = 'iPhone/iPad';
        } else if (Platform.isWindows) {
          devicePlatform = 'Windows';
          deviceInfo = 'Windows PC';
        } else if (Platform.isMacOS) {
          devicePlatform = 'macOS';
          deviceInfo = 'Mac';
        } else if (Platform.isLinux) {
          devicePlatform = 'Linux';
          deviceInfo = 'Linux PC';
        }

        // Get location (only on mobile)
        if (Platform.isAndroid || Platform.isIOS) {
          locationName = await _getLocationName();
        }
      }

      final updateData = <String, dynamic>{
        'lastActive': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
        'devicePlatform': devicePlatform,
      };

      if (locationName != null) {
        updateData['lastLocation'] = locationName;
      }

      await _db.collection('users').doc(_user!.uid).update(updateData);
    } catch (e) {
      print("Error updating user activity: $e");
    }
  }

  /// Get location name from GPS coordinates
  Future<String?> _getLocationName() async {
    try {
      // Import geolocator and geocoding dynamically to avoid issues on desktop
      final geolocator = await _importGeolocator();
      if (geolocator == null) return null;

      return geolocator;
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  /// Helper to get location (separated for cleaner error handling)
  Future<String?> _importGeolocator() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Check permissions
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // Low accuracy for faster result
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Convert to address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Return city/locality name
        return [
          place.locality,
          place.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }

      return null;
    } catch (e) {
      print("Geolocator error: $e");
      return null;
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
