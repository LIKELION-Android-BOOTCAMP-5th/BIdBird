import 'package:bidbird/core/supabase_manager.dart';

import '../price_Input_data/price_input_data.dart';

class PriceInputRepository {
  Future<void> placeBid(BidRequest request) async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('로그인 정보가 없습니다. 다시 로그인 해주세요.');
    }

    await supabase.from('bid_log').insert(<String, dynamic>{
      'item_id': request.itemId,
      'bid_user': user.id,
      'bid_price': request.bidPrice,
      'bid_time': DateTime.now().toIso8601String(),
    });

    await supabase
        .from('bid_status')
        .update({
          'text_code': 'BIDDING',
        })
        .eq('item_id', request.itemId)
        .eq('user_id', user.id);

    await supabase
        .from('items')
        .update({
          'current_price': request.bidPrice,
        })
        .eq('id', request.itemId);
  }
}

