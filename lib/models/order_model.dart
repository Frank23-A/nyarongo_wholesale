import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String customerId;
  final List<String> productIds;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.productIds,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'productIds': productIds,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAtValue = map['createdAt'];

    return OrderModel(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      productIds: List<String>.from(map['productIds'] as List? ?? const []),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.tryParse(createdAtValue as String? ?? '') ??
              DateTime.now(),
    );
  }
}
