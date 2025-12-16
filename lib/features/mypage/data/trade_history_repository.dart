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

    final List<dynamic> rows = await _client
        .from('items_detail')
        .select('item_id, title, thumbnail_image, buy_now_price, created_at')
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];

    final List<String> itemIds = [];
    final Map<String, Map<String, dynamic>> tradesById = {};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final itemId = row['item_id']?.toString();
      if (itemId == null) continue;
      itemIds.add(itemId);
      tradesById[itemId] = row;
    }

    final Map<String, Map<String, dynamic>> auctionsByItemId = {};
    if (itemIds.isNotEmpty) {
      final auctionRows = await _client
          .from('auctions')
          .select(
            'item_id, auction_end_at, current_price, last_bid_user_id, auction_status_code, trade_status_code',
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
      final item = tradesById[itemId] ?? <String, dynamic>{};
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
      final curCreated = DateTime.tryParse(row['created_at']?.toString() ?? '');

      if (prevCreated == null) {
        latestLogByAuctionId[auctionId] = row;
      } else if (curCreated != null && curCreated.isAfter(prevCreated)) {
        latestLogByAuctionId[auctionId] = row;
      }
    }

    final List<Map<String, dynamic>> logRows = latestLogByAuctionId.values
        .toList();

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
            'auction_id, item_id, current_price, auction_status_code, trade_status_code, auction_end_at, last_bid_user_id',
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
          .select('auction_id, item_id, auction_end_at, last_bid_user_id')
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

    //500번대우선없으면400번대사용
    final Map<String, Map<String, dynamic>> latestTradeByItem = {};
    for (final row in tradeRows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final created = DateTime.tryParse(row['created_at']?.toString() ?? '');
      final prevCreated = DateTime.tryParse(
        latestTradeByItem[itemId]?['created_at']?.toString() ?? '',
      );
      if (prevCreated == null ||
          (created != null && created.isAfter(prevCreated))) {
        latestTradeByItem[itemId] = row;
      }
    }

    final Map<String, Map<String, dynamic>> latestLogByItem = {};
    for (final row in logRows) {
      final auctionId = row['bid_status_id']?.toString();
      final auction = auctionsById[auctionId] ?? <String, dynamic>{};
      final itemId = auction['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final created = DateTime.tryParse(row['created_at']?.toString() ?? '');
      final prevCreated = DateTime.tryParse(
        latestLogByItem[itemId]?['created_at']?.toString() ?? '',
      );
      if (prevCreated == null ||
          (created != null && created.isAfter(prevCreated))) {
        latestLogByItem[itemId] = row;
      }
    }

    final Set<String> itemKeys = {};
    itemKeys.addAll(latestTradeByItem.keys);
    itemKeys.addAll(latestLogByItem.keys);

    final List<TradeHistoryItem> results = [];
    final nowUtc = DateTime.now().toUtc();

    for (final itemId in itemKeys) {
      final item = itemsById[itemId] ?? <String, dynamic>{};
      final endAt = auctionEndByItem[itemId];
      final tradeRow = latestTradeByItem[itemId];

      if (tradeRow != null) {
        final tradeCode = tradeRow['trade_status_code'] as int?;
        results.add(
          TradeHistoryItem(
            itemId: itemId,
            role: TradeRole.buyer,
            title: item['title']?.toString() ?? '',
            currentPrice: (tradeRow['price'] as num?)?.toInt() ?? 0,
            statusCode: tradeCode ?? 0,
            buyNowPrice: item['buy_now_price']?.toInt(),
            thumbnailUrl: item['thumbnail_image']?.toString(),
            createdAt: DateTime.tryParse(
              tradeRow['created_at']?.toString() ?? '',
            ),
            endAt: endAt,
          ),
        );
        continue;
      }

      final logRow = latestLogByItem[itemId];
      if (logRow != null) {
        final auctionId = logRow['bid_status_id']?.toString();
        final auction = auctionsById[auctionId] ?? <String, dynamic>{};
        final lastBidUserId = auction['last_bid_user_id']?.toString();
        final logCode = logRow['auction_log_code'] as int?;
        final createdAt = DateTime.tryParse(
          logRow['created_at']?.toString() ?? '',
        );
        final auctionStatus = auction['auction_status_code'] as int?;
        const endedStatusCodes = {321, 322};
        final endAtUtc = endAt?.toUtc();
        final isEndedByTime = endAtUtc != null && endAtUtc.isBefore(nowUtc);
        final isEndedByCode =
            auctionStatus != null && endedStatusCodes.contains(auctionStatus);
        final isEnded = isEndedByTime || isEndedByCode;
        final isWinner = lastBidUserId != null && lastBidUserId == user.id;
        final statusCode = (!isWinner && isEnded) ? 433 : (logCode ?? 0);

        results.add(
          TradeHistoryItem(
            itemId: itemId,
            role: TradeRole.buyer,
            title: item['title']?.toString() ?? '',
            currentPrice: (logRow['bid_price'] as num?)?.toInt() ?? 0,
            statusCode: statusCode,
            buyNowPrice: (item['buy_now_price'] as num?)?.toInt(),
            thumbnailUrl: item['thumbnail_image']?.toString(),
            createdAt: createdAt,
            endAt: endAt,
          ),
        );
      }
    }

    results.sort((a, b) {
      final da = a.endAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.endAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    return results;
  }
}
