class DeliveryModel {
  final String id;
  final String orderId;
  final String riderName;
  final String riderPhone;
  final String address;
  final String status;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.riderName,
    required this.riderPhone,
    required this.address,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'address': address,
      'status': status,
    };
  }

  factory DeliveryModel.fromMap(Map<String, dynamic> map, String id) {
    return DeliveryModel(
      id: id,
      orderId: map['orderId'] as String? ?? '',
      riderName: map['riderName'] as String? ?? '',
      riderPhone: map['riderPhone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      status: map['status'] as String? ?? 'scheduled',
    );
  }
}
