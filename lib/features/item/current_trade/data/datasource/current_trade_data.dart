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
      final logRows = await _supabase
          .from('auctions_status_log')
          .select('bid_status_id, user_id, bid_price, auction_log_code, created_at')
          .eq('user_id', user.id)
          .inFilter('auction_log_code', [410, 411, 430, 431])
          .order('created_at', ascending: false);

      final tradeRows = await _supabase
          .from('trade_status')
          .select('trade_id, item_id, price, trade_status_code, created_at')
          .eq('buyer_id', user.id)
          .eq('trade_status_code', 510);

      if (logRows.isEmpty && tradeRows.isEmpty) return [];

      final Set<String> auctionIds = {};
      for (final row in logRows) {
        final id = row['bid_status_id']?.toString();
        if (id != null && id.isNotEmpty) {
          auctionIds.add(id);
        }
      }

      final Map<String, Map<String, dynamic>> auctionsById = {};
      if (auctionIds.isNotEmpty) {
        final auctionsRows = await _supabase
            .from('auctions')
            .select(
                'auction_id, item_id, current_price, auction_status_code, trade_status_code')
            .inFilter('auction_id', auctionIds.toList());

        for (final row in auctionsRows) {
          final id = row['auction_id']?.toString();
          if (id != null) {
            auctionsById[id] = row;
          }
        }
      }

      final Set<String> itemIds = {};
      for (final auction in auctionsById.values) {
        final itemId = auction['item_id']?.toString();
        if (itemId != null) {
          itemIds.add(itemId);
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
        final itemRows = await _supabase
            .from('items_detail')
            .select('item_id, title, thumbnail_image')
            .inFilter('item_id', itemIds.toList());

        for (final row in itemRows) {
          final id = row['item_id']?.toString();
          if (id != null) {
            itemsById[id] = row;
          }
        }
      }

      final List<Map<String, dynamic>> merged = [];

      for (final row in logRows) {
        final auctionId = row['bid_status_id']?.toString();
        final auction = auctionsById[auctionId] ?? <String, dynamic>{};
        final int auctionStatusCode =
            (auction['auction_status_code'] as int?) ?? 0;
        final int tradeStatusCode =
            (auction['trade_status_code'] as int?) ?? 0;
        final itemId = auction['item_id']?.toString() ?? '';
        if (itemId.isEmpty) continue;

        final item = itemsById[itemId] ?? <String, dynamic>{};
        final int code = (row['auction_log_code'] as int?) ?? 0;
        String status;
        switch (code) {
          case 410:
            status = '경매 진행 중';
            break;
          case 411:
            status = '상위 입찰';
            break;
          case 430:
            status = '입찰 낙찰';
            break;
          case 431:
            // 즉시 구매 시도 로그이지만, 실제 경매/거래 상태에 따라 보정
            if (auctionStatusCode == 310) {
              // 즉시구매 실패 등으로 다시 경매 진행 중인 경우
              status = '경매 진행 중';
            } else if (auctionStatusCode == 322 ||
                tradeStatusCode == 520 ||
                tradeStatusCode == 550) {
              // 즉시 구매가 최종적으로 완료/거래 완료된 경우
              status = '즉시 구매 완료';
            } else {
              // 그 외에는 기본적으로 즉시 구매 낙찰로 취급
              status = '즉시 구매 낙찰';
            }
            break;
          default:
            status = '';
        }

        merged.add(<String, dynamic>{
          'item_id': itemId,
          'title': item['title']?.toString() ?? '',
          'price': row['bid_price'] as int? ?? 0,
          'thumbnail': item['thumbnail_image']?.toString(),
          'status': status,
          'created_at': row['created_at']?.toString(),
        });
      }

      for (final row in tradeRows) {
        final itemId = row['item_id']?.toString() ?? '';
        if (itemId.isEmpty) continue;
        final item = itemsById[itemId] ?? <String, dynamic>{};

        merged.add(<String, dynamic>{
          'item_id': itemId,
          'title': item['title']?.toString() ?? '',
          'price': row['price'] as int? ?? 0,
          'thumbnail': item['thumbnail_image']?.toString(),
          'status': '결제 대기',
          'created_at': row['created_at']?.toString(),
        });
      }

      merged.sort((a, b) {
        final ta = DateTime.tryParse(a['created_at']?.toString() ?? '');
        final tb = DateTime.tryParse(b['created_at']?.toString() ?? '');
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });

      return merged
          .map(
            (row) => BidHistoryItem(
              itemId: row['item_id']?.toString() ?? '',
              title: row['title']?.toString() ?? '',
              price: row['price'] as int? ?? 0,
              thumbnailUrl: row['thumbnail']?.toString(),
              status: row['status']?.toString() ?? '',
            ),
          )
          .toList();
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
      final itemRows = await _supabase
          .from('items_detail')
          .select(
              'item_id, title, thumbnail_image, visibility_status, created_at')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      if (itemRows.isEmpty) return [];

      final Map<String, Map<String, dynamic>> itemsById = {};
      final List<String> itemIds = [];
      for (final row in itemRows) {
        final id = row['item_id']?.toString();
        if (id != null) {
          itemsById[id] = row;
          itemIds.add(id);
        }
      }

      Map<String, int> priceByItemId = {};
      Map<String, int> auctionCodeByItemId = {};
      Map<String, int> tradeCodeByItemId = {};
      if (itemIds.isNotEmpty) {
        final priceRows = await _supabase
            .from('auctions')
            .select('item_id, current_price, auction_status_code, trade_status_code')
            .inFilter('item_id', itemIds)
            .eq('round', 1);

        for (final row in priceRows) {
          final id = row['item_id']?.toString();
          if (id != null) {
            priceByItemId[id] = (row['current_price'] as int?) ?? 0;
            final auctionCode = row['auction_status_code'] as int?;
            if (auctionCode != null) {
              auctionCodeByItemId[id] = auctionCode;
            }
            final tradeCode = row['trade_status_code'] as int?;
            if (tradeCode != null) {
              tradeCodeByItemId[id] = tradeCode;
            }
          }
        }
      }

      return itemIds.map((itemId) {
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final auctionCode = auctionCodeByItemId[itemId];
        final tradeCode = tradeCodeByItemId[itemId];
        final createdAt = item['created_at']?.toString() ?? '';

        String status;
        if (tradeCode == 550) {
          status = '거래 완료';
        } else if (tradeCode == 520) {
          status = '결제 완료';
        } else if (tradeCode == 510) {
          status = '결제 대기';
        } else {
          switch (auctionCode) {
            case 300:
              status = '경매 대기';
              break;
            case 310:
              status = '경매 진행 중';
              break;
            case 311:
              status = '즉시 구매 진행 중';
              break;
            case 321:
              status = '낙찰';
              break;
            case 322:
              status = '즉시 구매 완료';
              break;
            case 323:
              status = '유찰';
              break;
            default:
              status = '';
          }
        }

        return SaleHistoryItem(
          itemId: itemId,
          title: item['title']?.toString() ?? '',
          price: priceByItemId[itemId] ?? 0,
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