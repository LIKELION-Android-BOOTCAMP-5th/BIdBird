import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/managers/supabase_manager.dart';

class TradeHistoryRemoteDataSource {
  TradeHistoryRemoteDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<List<Map<String, dynamic>>> fetchSellerHistory(String userId) {
    return _client
        .from('items_detail')
        .select('''
          item_id,
          title,
          thumbnail_image,
          buy_now_price,
          created_at,
          auctions:auctions!inner(
            item_id,
            auction_end_at,
            current_price,
            last_bid_user_id,
            auction_status_code,
            trade_status_code,
            round
          )
        ''')
        .eq('seller_id', userId)
        .eq('auctions.round', 1)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchBuyerHistory(String userId) {
    return _client
        .from('auctions_status_log')
        .select('''
          bid_status_id,
          user_id,
          bid_price,
          auction_log_code,
          created_at,
          auctions:auctions!inner(
            auction_id,
            item_id,
            current_price,
            auction_status_code,
            trade_status_code,
            auction_end_at,
            last_bid_user_id,
            round,
            items_detail!inner(
              item_id,
              title,
              thumbnail_image,
              buy_now_price
            )
          )
        ''')
        .eq('user_id', userId)
        .eq('auctions.round', 1)
        .order('created_at', ascending: false);
  }

  String? get currentUserId => _client.auth.currentUser?.id;
}
