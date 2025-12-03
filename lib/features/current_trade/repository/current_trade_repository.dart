import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase_manager.dart';
import '../data/current_trade_data.dart';

abstract class CurrentTradeRepository {
  Future<List<BidHistoryItem>> fetchMyBidHistory();
  Future<List<SaleHistoryItem>> fetchMySaleHistory();
}

class CurrentTradeRepositoryImpl implements CurrentTradeRepository {
  final SupabaseClient _supabase;

  CurrentTradeRepositoryImpl({SupabaseClient? supabase}) 
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  @override
  Future<List<BidHistoryItem>> fetchMyBidHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final bidRows = await _supabase
          .from('bid_log')
          .select('item_id, bid_price, created_at, status, bid_user')
          .eq('bid_user', user.id)
          .order('created_at', ascending: false);

      if (bidRows.isEmpty) return [];

      final Map<String, Map<String, dynamic>> latestBidByItem = {};
      for (final raw in bidRows) {
        final row = raw as Map<String, dynamic>;
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
          itemsById[id] = row as Map<String, dynamic>;
        }
      }

      final statusRows = await _supabase
          .from('bid_status')
          .select('item_id, text_code')
          .eq('user_id', user.id)
          .inFilter('item_id', itemIds);

      final Map<String, String> statusByItemId = {};
      for (final row in statusRows) {
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
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error fetching bid history: $e');
      }
      rethrow;
    }
  }

  @override
  Future<List<SaleHistoryItem>> fetchMySaleHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final statusRows = await _supabase
          .from('bid_status')
          .select('item_id, text_code, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

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
          itemsById[id] = row as Map<String, dynamic>;
        }
      }

      return statusList.map((row) {
        final itemId = row['item_id']?.toString() ?? '';
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final status = row['text_code']?.toString() ?? '';
        final createdAt = row['created_at']?.toString() ?? '';

        return SaleHistoryItem(
          itemId: itemId,
          title: item['title']?.toString() ?? '',
          price: (item['current_price'] as int?) ?? 0,
          thumbnailUrl: item['thumbnail_image']?.toString(),
          status: status,
          date: _formatDateTime(createdAt),
        );
      }).toList();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error fetching sale history: $e');
      }
      rethrow;
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(isoString);
      if (dt == null) return isoString;

      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min';
    } catch (_) {
      return isoString;
    }
  }
}
