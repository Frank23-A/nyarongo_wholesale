class TrackingModel {
  final String id;
  final String orderId;
  final String status;
  final String currentLocation;
  final DateTime updatedAt;

  const TrackingModel({
    required this.id,
    required this.orderId,
    required this.status,
    required this.currentLocation,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'status': status,
      'currentLocation': currentLocation,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TrackingModel.fromMap(Map<String, dynamic> map, String id) {
    return TrackingModel(
      id: id,
      orderId: map['orderId'] as String? ?? '',
      status: map['status'] as String? ?? 'processing',
      currentLocation: map['currentLocation'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
