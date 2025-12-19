import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflinePaymentDatasource {
  OfflinePaymentDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  /// 직거래/계좌이체 결제 정보 저장 및 결제 완료 처리
  Future<void> completePayment({
    required String itemId,
    required bool isDirectTrade,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  }) async {
    final paymentType = isDirectTrade ? 'direct_trade' : 'bank_transfer';

    // Edge Function 호출
    final response = await _supabase.functions.invoke(
      'temporary-payments',
      body: {
        'item_id': itemId,
        'payment_type': paymentType,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder': accountHolder,
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Unknown error';
      throw Exception('결제 정보 저장 실패: $error');
    }
  }

  /// 결제 정보 조회
  Future<Map<String, dynamic>?> getPaymentInfo(String itemId) async {
    try {
      final result = await _supabase
          .from('temporary_payments')
          .select()
          .eq('item_id', itemId)
          .maybeSingle();

      return result;
    } catch (e) {
      print('결제 정보 조회 에러: $e');
      return null;
    }
  }
}
