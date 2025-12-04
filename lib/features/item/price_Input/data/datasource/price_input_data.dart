import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/price_Input/model/price_input_entity.dart';
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

    await _supabase.from('bid_log').insert(<String, dynamic>{
      'item_id': request.itemId,
      'bid_user': user.id,
      'bid_price': request.bidPrice,
      'bid_time': DateTime.now().toIso8601String(),
    });

    await _supabase
        .from('bid_status')
        .update({'text_code': 'BIDDING'})
        .eq('item_id', request.itemId)
        .eq('user_id', user.id);

    await _supabase
        .from('items')
        .update({'current_price': request.bidPrice})
        .eq('id', request.itemId);
  }
}