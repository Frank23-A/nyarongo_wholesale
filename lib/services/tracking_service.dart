import 'package:nyarongo_wholesale/models/tracking_model.dart';

class TrackingService {
  const TrackingService();

  TrackingModel getDefaultTracking(String orderId) {
    return TrackingModel(
      id: 'track_$orderId',
      orderId: orderId,
      status: 'processing',
      currentLocation: 'Warehouse',
      updatedAt: DateTime.now(),
    );
  }
}
