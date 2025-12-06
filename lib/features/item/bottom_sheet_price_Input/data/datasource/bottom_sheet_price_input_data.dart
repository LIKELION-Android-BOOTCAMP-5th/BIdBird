import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/bottom_sheet_price_Input/model/bottom_sheet_price_input_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceInputDatasource {
  PriceInputDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<void> placeBid(BidRequest request) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('로그인 정보가 없습니다. 다시 로그인 해주세요.');
    }

    final response = await _supabase.functions.invoke(
      'place-bid',
      body: <String, dynamic>{
        'itemId': request.itemId,
        'bidPrice': request.bidPrice,
        'isInstant': request.isInstant,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('입찰 처리에 실패했습니다. 다시 시도해주세요.');
    }

    final resultCode = data['result_code'] as String?;
    final message = data['message'] as String? ?? '입찰 처리에 실패했습니다.';

    if (resultCode != 'SUCCESS' && resultCode != 'INSTANT_BUY_TRIGGER') {
      throw Exception(message);
    }
  }
}