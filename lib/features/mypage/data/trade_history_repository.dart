import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/mypage/model/trade_history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TradeHistoryPage {
  TradeHistoryPage({required this.items, required this.hasMore});

  final List<TradeHistoryItem> items;
  final bool hasMore;
}

class TradeHistoryRepository {
  TradeHistoryRepository({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<TradeHistoryPage> fetchHistory({
    required TradeRole role,
    int? statusCode,
    required int page,
    required int pageSize,
  }) async {
    final List<TradeHistoryItem> allItems = role == TradeRole.seller
        ? await _fetchSellerHistory()
        : await _fetchBuyerHistory();

    final filtered = statusCode == null
        ? allItems
        : allItems.where((item) => item.statusCode == statusCode).toList();

    final start = (page - 1) * pageSize;
    if (start >= filtered.length) {
      return TradeHistoryPage(items: const [], hasMore: false);
    }

    final pageItems = filtered.skip(start).take(pageSize).toList();
    final hasMore = start + pageSize < filtered.length;
    return TradeHistoryPage(items: pageItems, hasMore: hasMore);
  }

  Future<List<TradeHistoryItem>> _fetchSellerHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final rows = await _client
        .from('items_detail')
        .select('item_id, title, thumbnail_image, buy_now_price, created_at')
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];

    final List<String> itemIds = [];
    final Map<String, Map<String, dynamic>> itemsById = {};
    for (final row in rows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null) continue;
      itemIds.add(itemId);
      itemsById[itemId] = row;
    }

    final Map<String, Map<String, dynamic>> auctionsByItemId = {};
    if (itemIds.isNotEmpty) {
      final auctionRows = await _client
          .from('auctions')
          .select(
            'item_id, current_price, auction_status_code, trade_status_code, auction_end_at',
          )
          .inFilter('item_id', itemIds)
          .eq('round', 1);

      for (final row in auctionRows) {
        final itemId = row['item_id']?.toString();
        if (itemId != null) {
          auctionsByItemId[itemId] = row;
        }
      }
    }

    final List<TradeHistoryItem> results = itemIds.map((itemId) {
      final item = itemsById[itemId] ?? <String, dynamic>{};
      final auction = auctionsByItemId[itemId] ?? <String, dynamic>{};
      final price = (auction['current_price'] as num?)?.toInt() ?? 0;
      final auctionCode = auction['auction_status_code'] as int?;
      final tradeCode = auction['trade_status_code'] as int?;
      final statusCode = tradeCode ?? auctionCode ?? 0;
      final endAt = DateTime.tryParse(
        auction['auction_end_at']?.toString() ?? '',
      );

      return TradeHistoryItem(
        itemId: itemId,
        role: TradeRole.seller,
        title: item['title']?.toString() ?? '',
        currentPrice: price,
        statusCode: statusCode,
        buyNowPrice: item['buy_now_price']?.toInt(),
        thumbnailUrl: item['thumbnail_image']?.toString(),
        createdAt: DateTime.tryParse(item['created_at']?.toString() ?? ''),
        endAt: endAt,
      );
    }).toList();

    results.sort((a, b) {
      final da = a.endAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.endAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    return results;
  }

  Future<List<TradeHistoryItem>> _fetchBuyerHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final rawLogRows = await _client
        .from('auctions_status_log')
        .select(
          'bid_status_id, user_id, bid_price, auction_log_code, created_at',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final Map<String, Map<String, dynamic>> latestLogByAuctionId = {};

    for (final dynamic row in rawLogRows) {
      if (row is! Map<String, dynamic>) continue;

      final String? auctionId = row['bid_status_id']?.toString();
      if (auctionId == null || auctionId.isEmpty) continue;

      final existing = latestLogByAuctionId[auctionId];
      if (existing == null) {
        latestLogByAuctionId[auctionId] = row;
        continue;
      }

      final prevCreated = DateTime.tryParse(
        existing['created_at']?.toString() ?? '',
      );
      final curCreated = DateTime.tryParse(
        row['created_at']?.toString() ?? '',
      );

      if (prevCreated == null) {
        latestLogByAuctionId[auctionId] = row;
      } else if (curCreated != null && curCreated.isAfter(prevCreated)) {
        latestLogByAuctionId[auctionId] = row;
      }
    }

    final List<Map<String, dynamic>> logRows =
        latestLogByAuctionId.values.toList();

    final tradeRows = await _client
        .from('trade_status')
        .select('item_id, price, trade_status_code, created_at')
        .eq('buyer_id', user.id)
        .order('created_at', ascending: false);

    if (logRows.isEmpty && tradeRows.isEmpty) return [];

    final Set<String> auctionIds = {};
    for (final row in logRows) {
      final id = row['bid_status_id']?.toString();
      if (id != null && id.isNotEmpty) {
        auctionIds.add(id);
      }
    }

    final Map<String, Map<String, dynamic>> auctionsById = {};
    final Map<String, DateTime?> auctionEndByItem = {};
    final Set<String> itemIds = {};
    if (auctionIds.isNotEmpty) {
      final auctionsRows = await _client
          .from('auctions')
          .select(
            'auction_id, item_id, current_price, auction_status_code, trade_status_code, auction_end_at',
          )
          .inFilter('auction_id', auctionIds.toList());

      for (final row in auctionsRows) {
        final id = row['auction_id']?.toString();
        if (id != null) {
          auctionsById[id] = row;
        }
        final itemId = row['item_id']?.toString();
        if (itemId != null) {
          auctionEndByItem[itemId] = DateTime.tryParse(
            row['auction_end_at']?.toString() ?? '',
          );
          itemIds.add(itemId);
        }
      }
    }

    final missingItemEndIds = itemIds
        .where((itemId) => !auctionEndByItem.containsKey(itemId))
        .toList();
    if (missingItemEndIds.isNotEmpty) {
      final extraRows = await _client
          .from('auctions')
          .select('auction_id, item_id, auction_end_at')
          .inFilter('item_id', missingItemEndIds);

      for (final row in extraRows) {
        final itemId = row['item_id']?.toString();
        if (itemId == null) continue;
        auctionEndByItem[itemId] ??= DateTime.tryParse(
          row['auction_end_at']?.toString() ?? '',
        );

        final auctionId = row['auction_id']?.toString();
        if (auctionId != null && !auctionsById.containsKey(auctionId)) {
          auctionsById[auctionId] = row;
        }
      }
    }

    for (final row in tradeRows) {
      final itemId = row['item_id']?.toString();
      if (itemId != null) {
        itemIds.add(itemId);
      }
    }

    final Map<String, Map<String, dynamic>> itemsById = {};
    if (itemIds.isNotEmpty) {
      final itemRows = await _client
          .from('items_detail')
          .select('item_id, title, thumbnail_image, buy_now_price')
          .inFilter('item_id', itemIds.toList());

      for (final row in itemRows) {
        final id = row['item_id']?.toString();
        if (id != null) {
          itemsById[id] = row;
        }
      }
    }

    final List<TradeHistoryItem> results = [];

    for (final row in logRows) {
      final auctionId = row['bid_status_id']?.toString();
      final auction = auctionsById[auctionId] ?? <String, dynamic>{};
      final itemId = auction['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final item = itemsById[itemId] ?? <String, dynamic>{};

      final logCode = row['auction_log_code'] as int?;
      final statusCode = logCode ?? 0;
      final price = (row['bid_price'] as num?)?.toInt() ?? 0;
      final endAt = auctionEndByItem[itemId];

      results.add(
        TradeHistoryItem(
          itemId: itemId,
          role: TradeRole.buyer,
          title: item['title']?.toString() ?? '',
          currentPrice: price,
          statusCode: statusCode,
          buyNowPrice: (item['buy_now_price'] as num?)?.toInt(),
          thumbnailUrl: item['thumbnail_image']?.toString(),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
          endAt: endAt,
        ),
      );
    }

    for (final row in tradeRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final item = itemsById[itemId] ?? <String, dynamic>{};
      final tradeCode = row['trade_status_code'] as int?;
      final statusCode = tradeCode ?? 0;
      final endAt = auctionEndByItem[itemId];

      results.add(
        TradeHistoryItem(
          itemId: itemId,
          role: TradeRole.buyer,
          title: item['title']?.toString() ?? '',
          currentPrice: (row['price'] as num?)?.toInt() ?? 0,
          statusCode: statusCode,
          buyNowPrice: item['buy_now_price']?.toInt(),
          thumbnailUrl: item['thumbnail_image']?.toString(),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
          endAt: endAt,
        ),
      );
    }

    results.sort((a, b) {
      final da = a.endAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.endAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    return results;
  }
}
