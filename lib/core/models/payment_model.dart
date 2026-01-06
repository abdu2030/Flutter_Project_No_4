import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String txRef;
  final String userId;
  final String courseId;
  final String courseTitle;
  final double amount;
  final String currency;
  final String status; // pending, success, failed
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentModel({
    required this.id,
    required this.txRef,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    this.currency = 'ETB',
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'txRef': txRef,
      'userId': userId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt,
    };
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      txRef: map['txRef'] ?? '',
      userId: map['userId'] ?? '',
      courseId: map['courseId'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'ETB',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
