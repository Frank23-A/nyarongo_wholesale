import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nyarongo_wholesale/models/order_model.dart';
import 'package:nyarongo_wholesale/services/firebase_service.dart';

class OrderService {
  const OrderService();

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      FirebaseService.firestore.collection('orders');

  Stream<List<OrderModel>> watchCustomerOrders(String customerId) {
    return watchAllOrders().map(
      (orders) => orders
          .where((order) => order.customerId == customerId)
          .toList(growable: false),
    );
  }

  Stream<List<OrderModel>> watchAllOrders() {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_ordersFromSnapshot);
  }

  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final orders = await getAllOrders();
    return orders
        .where((order) => order.customerId == customerId)
        .toList(growable: false);
  }

  Future<List<OrderModel>> getAllOrders() async {
    final snapshot =
        await _ordersCollection.orderBy('createdAt', descending: true).get();
    final orders = _ordersFromSnapshot(snapshot);
    return orders.isEmpty ? List<OrderModel>.from(_demoOrders) : orders;
  }

  Future<OrderModel> createDraftOrder({
    required String customerId,
    required List<String> productIds,
    required double totalAmount,
  }) async {
    final document = _ordersCollection.doc();
    final order = OrderModel(
      id: document.id,
      customerId: customerId,
      productIds: productIds,
      totalAmount: totalAmount,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await document.set(order.toMap());
    return order;
  }

  List<OrderModel> _ordersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((document) => OrderModel.fromMap(document.data(), document.id))
        .toList(growable: false);
  }
}

final List<OrderModel> _demoOrders = [
  OrderModel(
    id: 'ORD-1001',
    customerId: 'customer_demo',
    productIds: const ['prod_1', 'prod_2'],
    totalAmount: 8070,
    status: 'pending',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  OrderModel(
    id: 'ORD-1002',
    customerId: 'customer_demo',
    productIds: const ['prod_3'],
    totalAmount: 2280,
    status: 'shipped',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  OrderModel(
    id: 'ORD-1003',
    customerId: 'customer_demo',
    productIds: const ['prod_5'],
    totalAmount: 2840,
    status: 'delivered',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
  OrderModel(
    id: 'ORD-1004',
    customerId: 'retailer_17',
    productIds: const ['prod_4', 'prod_2'],
    totalAmount: 4140,
    status: 'confirmed',
    createdAt: DateTime.now().subtract(const Duration(hours: 18)),
  ),
];
