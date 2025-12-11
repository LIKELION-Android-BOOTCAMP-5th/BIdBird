import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/mypage/model/favorites_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesRepository {
  FavoritesRepository({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<List<FavoritesItem>> fetchFavorites() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final List<dynamic> rows = await _client
        .from('favorites')
        .select('id, item_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];

    final List<String> itemIds = [];
    final Map<String, Map<String, dynamic>> favoritesByItem = {};
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      itemIds.add(itemId);
      favoritesByItem[itemId] = row;
    }

    if (itemIds.isEmpty) return [];

    final Map<String, Map<String, dynamic>> itemsById = await _fetchItemsDetail(
      itemIds,
    );
    final Map<String, Map<String, dynamic>> auctionsByItemId =
        await _fetchAuctions(itemIds);

    return itemIds
        .map(
          (itemId) => _mapFavorites(
            itemId: itemId,
            favoriteRow: favoritesByItem[itemId],
            itemRow: itemsById[itemId],
            auctionRow: auctionsByItemId[itemId],
          ),
        )
        .whereType<FavoritesItem>() //null제거
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchItemsDetail(
    List<String> itemIds,
  ) async {
    final List<dynamic> rows = await _client
        .from('items_detail')
        .select('item_id, title, thumbnail_image, buy_now_price')
        .inFilter('item_id', itemIds);

    final Map<String, Map<String, dynamic>> map = {};
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final itemId = row['item_id']?.toString();
      if (itemId != null) {
        map[itemId] = row;
      }
    }
    return map;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchAuctions(
    List<String> itemIds,
  ) async {
    final List<dynamic> rows = await _client
        .from('auctions')
        .select(
          'item_id, current_price, auction_status_code, trade_status_code',
        )
        .inFilter('item_id', itemIds)
        .eq('round', 1);

    final Map<String, Map<String, dynamic>> map = {};
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final itemId = row['item_id']?.toString();
      if (itemId != null) {
        map[itemId] = row;
      }
    }
    return map;
  }

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

  FavoritesItem? _mapFavorites({
    required String itemId,
    Map<String, dynamic>? favoriteRow,
    Map<String, dynamic>? itemRow,
    Map<String, dynamic>? auctionRow,
  }) {
    if (favoriteRow == null) return null;

    final favoriteId = favoriteRow['id']?.toString() ?? '';
    final String title = itemRow?['title']?.toString() ?? '';
    final String? thumbnail = itemRow?['thumbnail_image']?.toString();
    final int currentPrice =
        (auctionRow?['current_price'] as num?)?.toInt() ?? 0;
    final int? buyNowPrice = (itemRow?['buy_now_price'] as num?)?.toInt();
    final int statusCode =
        (auctionRow?['trade_status_code'] as int?) ??
        (auctionRow?['auction_status_code'] as int?) ??
        0;

    return FavoritesItem(
      favoriteId: favoriteId,
      itemId: itemId,
      title: title,
      thumbnailUrl: thumbnail,
      currentPrice: currentPrice,
      buyNowPrice: buyNowPrice,
      statusCode: statusCode,
      isFavorite: true,
    );
  }
}
