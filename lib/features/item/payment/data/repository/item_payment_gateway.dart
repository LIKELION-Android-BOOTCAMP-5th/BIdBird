import 'package:bidbird/features/item/payment/model/item_payment_request.dart';

abstract class ItemPaymentGateway {
  Future<bool> handlePaymentResult({
    required Map<String, dynamic> result,
    required ItemPaymentRequest request,
  });
}
