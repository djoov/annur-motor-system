import 'package:cloud_firestore/cloud_firestore.dart';

class DebtPaymentLog {
  final DateTime date;
  final int amount;
  final String note;

  DebtPaymentLog({
    required this.date,
    required this.amount,
    required this.note,
  });

  factory DebtPaymentLog.fromMap(Map<String, dynamic> map) {
    return DebtPaymentLog(
      date: (map['date'] as Timestamp).toDate(),
      amount: map['amount'] as int,
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': Timestamp.fromDate(date), 'amount': amount, 'note': note};
  }
}

class DebtModel {
  final String id;
  final String customerId;
  final String customerName; // Cache name for easier display
  final String transactionId;
  final int totalAmount;
  final int remainingAmount;
  final String status; // 'unpaid', 'partial', 'paid'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final List<DebtPaymentLog> logs;

  DebtModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.transactionId,
    required this.totalAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.logs = const [],
  });

  factory DebtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DebtModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      transactionId: data['transactionId'] ?? '',
      totalAmount: data['totalAmount'] ?? 0,
      remainingAmount: data['remainingAmount'] ?? 0,
      status: data['status'] ?? 'unpaid',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      logs:
          (data['logs'] as List<dynamic>?)
              ?.map((e) => DebtPaymentLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'transactionId': transactionId,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'logs': logs.map((e) => e.toMap()).toList(),
    };
  }
}
