import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String contactPerson;

  SupplierModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.contactPerson = '',
  });

  factory SupplierModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupplierModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'contactPerson': contactPerson,
    };
  }
}
