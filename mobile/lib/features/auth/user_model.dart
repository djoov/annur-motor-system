import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String role; // 'admin' or 'staff'
  final String name;

  // Activity tracking fields
  final DateTime? lastActive;
  final String? deviceInfo;
  final String? devicePlatform;
  final String? lastLocation;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.lastActive,
    this.deviceInfo,
    this.devicePlatform,
    this.lastLocation,
    this.isOnline = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse lastActive timestamp
    DateTime? lastActiveTime;
    if (data['lastActive'] != null) {
      if (data['lastActive'] is Timestamp) {
        lastActiveTime = (data['lastActive'] as Timestamp).toDate();
      }
    }

    // Determine online status (active within last 5 minutes)
    bool online = false;
    if (lastActiveTime != null) {
      final diff = DateTime.now().difference(lastActiveTime);
      online = diff.inMinutes < 5;
    }

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'pending',
      name: data['name'] ?? 'User',
      lastActive: lastActiveTime,
      deviceInfo: data['deviceInfo'],
      devicePlatform: data['devicePlatform'],
      lastLocation: data['lastLocation'],
      isOnline: online,
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role, 'name': name};
  }

  /// Get formatted "last seen" string
  String get lastSeenText {
    if (lastActive == null) return 'Tidak diketahui';
    if (isOnline) return 'Online sekarang';

    final diff = DateTime.now().difference(lastActive!);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${lastActive!.day}/${lastActive!.month}/${lastActive!.year}';
  }

  /// Get session duration if online
  String get sessionDurationText {
    if (lastActive == null || !isOnline) return '-';
    final diff = DateTime.now().difference(lastActive!);
    if (diff.inMinutes < 1) return 'Baru mulai';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit';
    return '${diff.inHours} jam ${diff.inMinutes % 60} menit';
  }
}
