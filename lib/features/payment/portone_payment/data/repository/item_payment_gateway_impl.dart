import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/payment/portone_payment/data/repository/item_payment_gateway.dart';
import 'package:bidbird/features/payment/portone_payment/model/item_payment_request.dart';

class ItemPaymentGatewayImpl implements ItemPaymentGateway {
  @override
  Future<bool> handlePaymentResult({
    required Map<String, dynamic> result,
    required ItemPaymentRequest request,
  }) async {
    final String? errorCode = result['code'] as String?;
    final bool portoneSuccess = errorCode == null || errorCode.isEmpty;

    if (!portoneSuccess) {
      return false;
    }

    final txId = result['txId'] ?? result['transactionId'];
    final paymentId = result['paymentId'];
    
    if (txId == null || paymentId == null) {
      return false;
    }

    final resultAmount = result['amount'] as int?;
    if (resultAmount != null && resultAmount != request.amount) {
      return false;
    }

    try {
      final supabase = SupabaseManager.shared.supabase;

      final response = await supabase.functions.invoke(
        'payment',
        body: <String, dynamic>{
          'payment_type': 'auction',
          'item_id': request.itemId,
          'txId': txId,
          'paymentId': paymentId,
          'amount': request.amount,
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      return false;
    }
  }
}
