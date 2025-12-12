import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
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
      // 입찰 내역: auctions 테이블에서 현재 사용자가 마지막 입찰자인 경매만 조회
      final auctionRows = await _supabase
          .from('auctions')
          .select(
            'auction_id, item_id, current_price, auction_status_code, trade_status_code, created_at',
          )
          .eq('last_bid_user_id', user.id)
          .order('created_at', ascending: false);

      if (auctionRows.isEmpty) return [];

      // 필요한 item_id만 모아서 items_detail에서 제목/썸네일 조회
      final Set<String> itemIds = {};
      for (final row in auctionRows) {
        final itemId = row['item_id']?.toString();
        if (itemId != null && itemId.isNotEmpty) {
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
          if (id != null && id.isNotEmpty) {
            itemsById[id] = row;
          }
        }
      }

      // auctions의 경매/거래 상태 코드 기준으로 상태 문자열 생성
      String _buildStatus({required int auctionCode, required int tradeCode}) {
        if (tradeCode == 550) {
          return '거래 완료';
        } else if (tradeCode == 520) {
          return '결제 완료';
        } else if (tradeCode == 510) {
          return '결제 대기';
        }

        switch (auctionCode) {
          case 300:
            return '경매 대기';
          case 310:
            return '경매 진행 중';
          case 311:
            return '즉시 구매 진행 중';
          case 321:
            return '입찰 낙찰';
          case 322:
            return '즉시 구매 완료';
          case 323:
            return '유찰';
          default:
            return '';
        }
      }

      final List<BidHistoryItem> results = [];

      for (final row in auctionRows) {
        final itemId = row['item_id']?.toString() ?? '';
        if (itemId.isEmpty) continue;

        final item = itemsById[itemId] ?? <String, dynamic>{};
        final auctionCode = row['auction_status_code'] as int? ?? 0;
        final tradeCode = row['trade_status_code'] as int? ?? 0;

        results.add(
          BidHistoryItem(
            itemId: itemId,
            title: item['title']?.toString() ?? '',
            price: row['current_price'] as int? ?? 0,
            thumbnailUrl: item['thumbnail_image']?.toString(),
            status: _buildStatus(
              auctionCode: auctionCode,
              tradeCode: tradeCode,
            ),
          ),
        );
      }

      // DB 쿼리에서 이미 created_at 내림차순 정렬, 그대로 사용
      return results;
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
        final auctionCode = auctionCodeByItemId[itemId] ?? 0;
        final tradeCode = tradeCodeByItemId[itemId] ?? 0;
        final createdAt = item['created_at']?.toString() ?? '';

        // 입찰 내역과 동일한 규칙으로 상태 문자열 생성
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
              status = '입찰 낙찰';
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
          date: formatDateTimeFromIso(createdAt),
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