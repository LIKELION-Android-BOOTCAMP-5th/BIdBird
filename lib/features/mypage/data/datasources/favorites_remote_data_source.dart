import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/managers/supabase_manager.dart';

class FavoritesRemoteDataSource {
  FavoritesRemoteDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchFavoritesRows() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final List<dynamic> rows = await _client
        // .from('favorites')
        // .select('id, item_id, created_at')
        // .eq('user_id', user.id)
        // .order('created_at', ascending: false);
        .from('favorites')
        .select('''
          id,
          item_id,
          created_at,
          item:items_detail(
            item_id,
            title,
            thumbnail_image,
            buy_now_price,
            auctions:auctions!inner(
              item_id,
              current_price,
              auction_status_code,
              trade_status_code,
              round
            )
          )
        ''')
        .eq('user_id', user.id)
        .eq('item.auctions.round', 1)
        .order('created_at', ascending: false);

    return rows.whereType<Map<String, dynamic>>().toList();
  }

  // Future<List<Map<String, dynamic>>> fetchItemsDetail(List<String> itemIds) {
  //   return _client
  //       .from('items_detail')
  //       .select('item_id, title, thumbnail_image, buy_now_price')
  //       .inFilter('item_id', itemIds);
  // }

  // Future<List<Map<String, dynamic>>> fetchAuctions(List<String> itemIds) {
  //   return _client
  //       .from('auctions')
  //       .select('item_id, current_price, auction_status_code')
  //       .inFilter('item_id', itemIds)
  //       .eq('round', 1);
  // }

  Future<void> removeFavorite(String itemId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    await _client
        .from('favorites')
        .delete()
        .eq('item_id', itemId)
        .eq('user_id', user.id);
  }

  Future<void> addFavorite(String itemId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    await _client.from('favorites').insert(<String, dynamic>{
      'item_id': itemId,
      'user_id': user.id,
    });
  }
}
