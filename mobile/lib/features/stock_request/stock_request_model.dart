import 'package:cloud_firestore/cloud_firestore.dart';

class StockRequest {
  final String id;
  final String itemId;
  final String itemName;
  final String? itemImage;
  final int requestQty;
  final String status; // 'pending', 'approved', 'rejected'
  final String requesterId;
  final String requesterName;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolverId;
  final String? resolverName;

  StockRequest({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.itemImage,
    required this.requestQty,
    required this.status,
    required this.requesterId,
    required this.requesterName,
    required this.createdAt,
    this.resolvedAt,
    this.resolverId,
    this.resolverName,
  });

  factory StockRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockRequest(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemImage: data['itemImage'],
      requestQty: (data['requestQty'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'pending',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolverId: data['resolverId'],
      resolverName: data['resolverName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemImage': itemImage,
      'requestQty': requestQty,
      'status': status,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': resolvedAt,
      'resolverId': resolverId,
      'resolverName': resolverName,
    };
  }
}
