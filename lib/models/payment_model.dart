class PaymentModel {
  final String id;
  final String orderId;
  final double amount;
  final String method;
  final String status;
  final DateTime paidAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'method': method,
      'status': status,
      'paidAt': paidAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      orderId: map['orderId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      method: map['method'] as String? ?? 'mpesa',
      status: map['status'] as String? ?? 'pending',
      paidAt: DateTime.tryParse(map['paidAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
