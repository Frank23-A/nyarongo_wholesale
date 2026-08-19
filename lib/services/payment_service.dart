import 'package:nyarongo_wholesale/models/payment_model.dart';

class PaymentService {
  const PaymentService();

  Future<PaymentModel> initializePayment({
    required String orderId,
    required double amount,
  }) async {
    return PaymentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: orderId,
      amount: amount,
      method: 'mpesa',
      status: 'pending',
      paidAt: DateTime.now(),
    );
  }
}
