import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/payment/portone_payment/data/repository/item_payment_gateway.dart';
import 'package:bidbird/features/payment/portone_payment/model/item_payment_request.dart';
import 'package:flutter/foundation.dart';

class ItemPaymentGatewayImpl implements ItemPaymentGateway {
  @override
  Future<bool> handlePaymentResult({
    required Map<String, dynamic> result,
    required ItemPaymentRequest request,
  }) async {
    debugPrint('[PortonePayment] raw result: $result');

    final String? errorCode = result['code'] as String?;
    final bool portoneSuccess = errorCode == null || errorCode.isEmpty;

    if (!portoneSuccess) {
      return false;
    }

    try {
      final supabase = SupabaseManager.shared.supabase;

      final response = await supabase.functions.invoke(
        'payment-complete',
        body: <String, dynamic>{
          'payment_type': 'auction',
          'item_id': request.itemId,
          'amount': request.amount,
          'txId': result['txId'] ?? result['transactionId'],
          'paymentId': result['paymentId'],
        },
      );

      debugPrint('[PortonePayment] payment-complete response: ${response.data}');

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      debugPrint('[PortonePayment] payment-complete error: $e\n$st');
      return false;
    }
  }
}
