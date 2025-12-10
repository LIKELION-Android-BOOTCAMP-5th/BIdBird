import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/buy_now_input_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuyNowInputDatasource {
  BuyNowInputDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<void> placeBid(BuyNowBidRequest request) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('로그인 정보가 없습니다. 다시 로그인 해주세요.');
    }

    final String rpcName = request.isInstant
        ? 'place_bid_instant'
        : 'place_bid_normal';

    final response = await _supabase.rpc(
      rpcName,
      params: <String, dynamic>{
        'p_item_id': request.itemId,
        'p_bidder_id': user.id,
        'p_bid_price': request.bidPrice,
      },
    );

    final data = response;

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
