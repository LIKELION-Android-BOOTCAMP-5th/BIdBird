import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/managers/supabase_manager.dart';

class TradeHistoryRemoteDataSource {
  TradeHistoryRemoteDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<List<Map<String, dynamic>>> fetchSellerItems(String userId) {
    return _client
        .from('items_detail')
        .select('item_id, title, thumbnail_image, buy_now_price, created_at')
        .eq('seller_id', userId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchAuctionsByItemIds(
    List<String> itemIds,
  ) {
    return _client
        .from('auctions')
        .select(
          'item_id, auction_end_at, current_price, last_bid_user_id, auction_status_code, trade_status_code',
        )
        .inFilter('item_id', itemIds)
        .eq('round', 1);
  }

  Future<List<Map<String, dynamic>>> fetchBuyerLogs(String userId) {
    return _client
        .from('auctions_status_log')
        .select(
          'bid_status_id, user_id, bid_price, auction_log_code, created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchTradeStatus(String userId) {
    return _client
        .from('trade_status')
        .select('item_id, price, trade_status_code, created_at')
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchAuctionsByIds(
    List<String> auctionIds,
  ) {
    return _client
        .from('auctions')
        .select(
          'auction_id, item_id, current_price, auction_status_code, trade_status_code, auction_end_at, last_bid_user_id',
        )
        .inFilter('auction_id', auctionIds);
  }

  Future<List<Map<String, dynamic>>> fetchAuctionEndsByItemIds(
    List<String> itemIds,
  ) {
    return _client
        .from('auctions')
        .select('auction_id, item_id, auction_end_at, last_bid_user_id')
        .inFilter('item_id', itemIds);
  }

  Future<List<Map<String, dynamic>>> fetchItemsByIds(List<String> itemIds) {
    return _client
        .from('items_detail')
        .select('item_id, title, thumbnail_image, buy_now_price')
        .inFilter('item_id', itemIds);
  }

  String? get currentUserId => _client.auth.currentUser?.id;
}
