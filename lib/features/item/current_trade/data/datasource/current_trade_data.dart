import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/current_trade/model/current_trade_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrentTradeDatasource {
  CurrentTradeDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<List<BidHistoryItem>> fetchMyBidHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // 내가 참여한 아이템 id 목록을 bid_status에서 먼저 조회 (bid_user 기준)
      final statusRows = await _supabase
          .from('bid_status')
          .select('item_id')
          .eq('bid_user', user.id);

      if (statusRows.isEmpty) return [];

      final Set<String> joinedItemIds = {};
      for (final row in statusRows) {
        final itemId = row['item_id']?.toString();
        if (itemId != null && itemId.isNotEmpty) {
          joinedItemIds.add(itemId);
        }
      }

      if (joinedItemIds.isEmpty) return [];

      // 해당 아이템들에 대한 입찰 로그에서 가장 최근 입찰만 사용
      final bidRows = await _supabase
          .from('bid_log')
          .select('item_id, bid_price, created_at, status')
          .inFilter('item_id', joinedItemIds.toList())
          .order('created_at', ascending: false);

      if (bidRows.isEmpty) return [];

      final Map<String, Map<String, dynamic>> latestBidByItem = {};
      for (final row in bidRows) {
        final itemId = row['item_id']?.toString();
        if (itemId == null || itemId.isEmpty) continue;
        if (!latestBidByItem.containsKey(itemId)) {
          latestBidByItem[itemId] = row;
        }
      }

      final bids = latestBidByItem.values.toList();
      final itemIds = bids
          .map((row) => row['item_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (itemIds.isEmpty) return [];

      final itemRows = await _supabase
          .from('items')
          .select('id, title, thumbnail_image, current_price')
          .inFilter('id', itemIds);

      final Map<String, Map<String, dynamic>> itemsById = {};
      for (final row in itemRows) {
        final id = row['id']?.toString();
        if (id != null) {
          itemsById[id] = row;
        }
      }

      final statusRowsForItems = await _supabase
          .from('bid_status')
          .select('item_id, text_code')
          .eq('seller_id', user.id)
          .inFilter('item_id', itemIds);

      final Map<String, String> statusByItemId = {};
      for (final row in statusRowsForItems) {
        final id = row['item_id']?.toString();
        if (id != null) {
          statusByItemId[id] = row['text_code']?.toString() ?? '';
        }
      }

      return bids.map((row) {
        final itemId = row['item_id']?.toString() ?? '';
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final bidPrice = row['bid_price'] as int? ?? 0;
        final currentPrice = item['current_price'] as int? ?? 0;
        final rawStatus = statusByItemId[itemId] ?? '';

        String displayStatus;
        final bool isTopBidder = currentPrice > 0 && bidPrice == currentPrice;

        if (rawStatus.contains('입찰 제한') || rawStatus.contains('거래정지')) {
          displayStatus = '거래정지';
        } else if (isTopBidder) {
          displayStatus = '최고가 입찰';
        } else {
          displayStatus = '패찰';
        }

        return BidHistoryItem(
          itemId: itemId,
          title: item['title']?.toString() ?? '',
          price: bidPrice,
          thumbnailUrl: item['thumbnail_image']?.toString(),
          status: displayStatus,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching bid history: $e');
      }
      rethrow;
    }
  }

  Future<List<SaleHistoryItem>> fetchMySaleHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final statusRows = await _supabase
          .from('bid_status')
          .select('item_id, text_code, int_code, update_at')
          .eq('seller_id', user.id)
          .inFilter('int_code', [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008])
          .order('update_at', ascending: false);

      if (statusRows.isEmpty) return [];

      final List<Map<String, dynamic>> statusList =
          List<Map<String, dynamic>>.from(statusRows);

      final itemRows = await _supabase
          .from('items')
          .select('id, title, current_price, thumbnail_image')
          .eq('seller_id', user.id);

      final Map<String, Map<String, dynamic>> itemsById = {};
      for (final row in itemRows) {
        final id = row['id']?.toString();
        if (id != null) {
          itemsById[id] = row;
        }
      }

      return statusList.map((row) {
        final itemId = row['item_id']?.toString() ?? '';
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final status = row['text_code']?.toString() ?? '';
        final createdAt = row['update_at']?.toString() ?? '';

        return SaleHistoryItem(
          itemId: itemId,
          title: item['title']?.toString() ?? '',
          price: (item['current_price'] as int?) ?? 0,
          thumbnailUrl: item['thumbnail_image']?.toString(),
          status: status,
          date: CurrentTradeDateFormatter.format(createdAt),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching sale history: $e');
      }
      rethrow;
    }
  }
}