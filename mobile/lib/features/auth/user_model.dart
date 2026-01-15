import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String role; // 'admin' or 'staff'
  final String name;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'staff', // Default to staff for safety
      name: data['name'] ?? 'User',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role, 'name': name};
  }
}
