import 'package:cloud_firestore/cloud_firestore.dart';

class StockRequestModel {
  final String id;
  final String itemId;
  final String itemName;
  final String itemCode; // For display
  final int requestedQty;
  final String requesterId;
  final String requesterName;
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? resolvedAt;
  final String? resolverId;
  final String? resolverName;

  StockRequestModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemCode,
    required this.requestedQty,
    required this.requesterId,
    required this.requesterName,
    required this.createdAt,
    this.status = 'pending',
    this.resolvedAt,
    this.resolverId,
    this.resolverName,
  });

  factory StockRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StockRequestModel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemCode: data['itemCode'] ?? '',
      requestedQty: data['requestedQty'] ?? 0,
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      status: data['status'] ?? 'pending',
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolverId: data['resolverId'],
      resolverName: data['resolverName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemCode': itemCode,
      'requestedQty': requestedQty,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolverId': resolverId,
      'resolverName': resolverName,
    };
  }
}
