import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/features/item/bid/buy_now/model/buy_now_input_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuyNowInputDatasource {
  BuyNowInputDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<void> placeBid(BuyNowBidRequest request) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(ItemRegistrationErrorMessages.loginRequired);
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
      throw Exception(BidErrorMessages.bidProcessingFailed);
    }

    final resultCode = data['result_code'] as String?;
    final message = data['message'] as String? ?? BidErrorMessages.bidProcessingFailedDefault;

    if (resultCode != 'SUCCESS' && resultCode != 'INSTANT_BUY_TRIGGER') {
      throw Exception(message);
    }
  }
}
