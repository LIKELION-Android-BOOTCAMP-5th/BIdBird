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

    final response = await _supabase.rpc(
      rpcName,
      params: {
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

  Future<String?> createChatRoom(String itemId, String sellerId, String buyerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception(ItemRegistrationErrorMessages.loginRequired);
    }
    // 채팅방 생성 RPC 호출 (가정: create_chat_room 함수가 Supabase에 있음)
    final response = await _supabase.rpc('create_chat_room', params: {
      'p_item_id': itemId,
      'p_seller_id': sellerId,
      'p_buyer_id': buyerId,
    });
    final data = response as Map<String, dynamic>?;
    if (data != null && data['room_id'] != null) {
      return data['room_id'] as String;
    }
    return null;
  }
}
