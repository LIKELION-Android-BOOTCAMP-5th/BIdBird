import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/features/bid/domain/entities/bid_request_entity.dart';
import 'package:bidbird/features/bid/domain/entities/buy_now_bid_request_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BidDatasource {
  BidDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<void> placeBid(BidRequest request) async {
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

    if (data is! Map<String, dynamic>) {
      throw Exception(BidErrorMessages.bidProcessingFailed);
    }

    final resultCode = getNullableStringFromRow(data, 'result_code');
    final message = getNullableStringFromRow(data, 'message') ??
        BidErrorMessages.bidProcessingFailedDefault;

    if (resultCode != 'SUCCESS' && resultCode != 'INSTANT_BUY_TRIGGER') {
      throw Exception(message);
    }
  }

  Future<void> placeBuyNowBid(BuyNowBidRequest request) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(ItemRegistrationErrorMessages.loginRequired);
    }

    final String rpcName = request.isInstant
        ? 'place_bid_instant'
        : 'place_bid_normal';

    await _supabase.rpc(
      rpcName,
      params: {
        'p_item_id': request.itemId,
        'p_bid_price': request.bidPrice,
      },
    );
      throw Exception(BidErrorMessages.bidProcessingFailed);
    }

    final resultCode = getNullableStringFromRow(data, 'result_code');
    final message = getNullableStringFromRow(data, 'message') ??
        BidErrorMessages.bidProcessingFailedDefault;

    if (resultCode != 'SUCCESS' && resultCode != 'INSTANT_BUY_TRIGGER') {
      throw Exception(message);
    }
  }
}



