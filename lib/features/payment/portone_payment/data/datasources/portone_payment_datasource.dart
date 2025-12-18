import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Portone 결제 데이터 소스
class PortonePaymentDatasource {
  PortonePaymentDatasource({SupabaseClient? client})
      : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  /// 결제 처리 엣지 펑션 호출
  /// 
  /// [itemId] 아이템 ID
  /// [txId] 트랜잭션 ID
  /// [paymentId] 결제 ID
  /// [amount] 결제 금액
  /// 
  /// Returns 성공 여부
  Future<bool> processPayment({
    required String itemId,
    required String txId,
    required String paymentId,
    required int amount,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'payment_v2',
        body: <String, dynamic>{
          'payment_type': 'auction',
          'item_id': itemId,
          'txId': txId,
          'paymentId': paymentId,
          'amount': amount,
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}



