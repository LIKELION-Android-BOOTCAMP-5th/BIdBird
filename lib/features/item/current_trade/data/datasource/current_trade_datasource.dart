import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:bidbird/features/item/model/trade_status_codes.dart';
import 'package:bidbird/features/item/current_trade/model/current_trade_entity.dart';
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
      final Set<String> itemIds = auctionRows
          .map((row) => getNullableStringFromRow(row, 'item_id'))
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet();

      final Map<String, Map<String, dynamic>> itemsById = {};
      Set<String> itemIdsWithShipping = {};
      
      if (itemIds.isNotEmpty) {
        // items_detail과 shipping_info를 병렬로 조회
        final results = await Future.wait([
          _supabase
              .from('items_detail')
              .select('item_id, title, thumbnail_image')
              .inFilter('item_id', itemIds.toList()),
          _supabase
              .from('shipping_info')
              .select('item_id')
              .inFilter('item_id', itemIds.toList()),
        ], eagerError: false);

        final itemRows = results[0] as List<dynamic>;
        final shippingRows = results[1] as List<dynamic>;

        for (final row in itemRows) {
          final id = getNullableStringFromRow(row, 'item_id');
          if (id != null && id.isNotEmpty) {
            itemsById[id] = row;
          }
        }

        for (final row in shippingRows) {
          final id = getNullableStringFromRow(row, 'item_id');
          if (id != null && id.isNotEmpty) {
            itemIdsWithShipping.add(id);
          }
        }
      }

      // auctions의 경매/거래 상태 코드 기준으로 상태 문자열 생성
      String buildStatus({
        required int auctionCode,
        required int tradeCode,
        required String itemId,
      }) {
        if (tradeCode == TradeStatusCode.completed) {
          return '거래 완료';
        } else if (tradeCode == TradeStatusCode.shippingInfoRequired) {
          // 배송 정보가 있으면 "배송 중", 없으면 "결제 완료"
          return itemIdsWithShipping.contains(itemId) ? '배송 중' : '결제 완료';
        } else if (tradeCode == TradeStatusCode.paymentRequired) {
          return '결제 대기';
        }

        switch (auctionCode) {
          case AuctionStatusCode.ready:
            return '경매 대기';
          case AuctionStatusCode.inProgress:
            return '경매 진행 중';
          case AuctionStatusCode.instantBuyPaymentPending:
            return '즉시 구매 진행 중';
          case AuctionStatusCode.bidWon:
            return '입찰 낙찰';
          case AuctionStatusCode.instantBuyCompleted:
            return '즉시 구매 완료';
          case AuctionStatusCode.failed:
            return '유찰';
          default:
            return '';
        }
      }

      final List<BidHistoryItem> results = [];

      for (final row in auctionRows) {
        final itemId = getStringFromRow(row, 'item_id');
        if (itemId.isEmpty) continue;

        final item = itemsById[itemId] ?? <String, dynamic>{};
        final auctionCode = getIntFromRow(row, 'auction_status_code');
        final tradeCode = getIntFromRow(row, 'trade_status_code');

        results.add(
          BidHistoryItem(
            itemId: itemId,
            title: getStringFromRow(item, 'title'),
            price: getIntFromRow(row, 'current_price'),
            thumbnailUrl: getNullableStringFromRow(item, 'thumbnail_image'),
            status: buildStatus(
              auctionCode: auctionCode,
              tradeCode: tradeCode,
              itemId: itemId,
            ),
            tradeStatusCode: tradeCode,
            auctionStatusCode: auctionCode,
            hasShippingInfo: itemIdsWithShipping.contains(itemId),
          ),
        );
      }

      // DB 쿼리에서 이미 created_at 내림차순 정렬, 그대로 사용
      return results;
    } catch (e) {
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
        final id = getNullableStringFromRow(row, 'item_id');
        if (id != null && id.isNotEmpty) {
          itemsById[id] = row;
          itemIds.add(id);
        }
      }

      Map<String, int> priceByItemId = {};
      Map<String, int> auctionCodeByItemId = {};
      Map<String, int> tradeCodeByItemId = {};
      Set<String> itemIdsWithShipping = {};
      
      if (itemIds.isNotEmpty) {
        // auctions와 shipping_info를 병렬로 조회
        final results = await Future.wait([
          _supabase
              .from('auctions')
              .select('item_id, current_price, auction_status_code, trade_status_code, round, created_at')
              .inFilter('item_id', itemIds)
              .order('round', ascending: false)
              .order('created_at', ascending: false),
          _supabase
              .from('shipping_info')
              .select('item_id')
              .inFilter('item_id', itemIds),
        ], eagerError: false);

        final priceRows = results[0] as List<dynamic>;
        final shippingRows = results[1] as List<dynamic>;
        
        // 같은 item_id에 여러 round가 있으면 trade_status_code가 null이 아닌 것을 우선 사용
        final Map<String, Map<String, dynamic>> bestAuctionsByItemId = {};
        for (final row in priceRows) {
          final id = getNullableStringFromRow(row, 'item_id');
          if (id == null || id.isEmpty) continue;
          
          final existing = bestAuctionsByItemId[id];
          final tradeCode = getNullableIntFromRow(row, 'trade_status_code');
          final existingTradeCode = existing != null ? getNullableIntFromRow(existing, 'trade_status_code') : null;
          
          // trade_status_code가 null이 아닌 것을 우선, 없으면 가장 최근 것
          if (existing == null || 
              (tradeCode != null && existingTradeCode == null) ||
              (tradeCode != null && existingTradeCode != null && 
               getIntFromRow(row, 'round') > getIntFromRow(existing, 'round'))) {
            bestAuctionsByItemId[id] = row;
          }
        }

        for (final entry in bestAuctionsByItemId.entries) {
          final id = entry.key;
          final row = entry.value;
          priceByItemId[id] = getIntFromRow(row, 'current_price');
          final auctionCode = getNullableIntFromRow(row, 'auction_status_code');
          if (auctionCode != null) {
            auctionCodeByItemId[id] = auctionCode;
          }
          final tradeCode = getNullableIntFromRow(row, 'trade_status_code');
          if (tradeCode != null) {
            tradeCodeByItemId[id] = tradeCode;
          }
        }

        // 배송 정보 처리
        for (final row in shippingRows) {
          final id = getNullableStringFromRow(row, 'item_id');
          if (id != null && id.isNotEmpty) {
            itemIdsWithShipping.add(id);
          }
        }
      }

      return itemIds.map((itemId) {
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final auctionCode = auctionCodeByItemId[itemId] ?? 0;
        final tradeCode = tradeCodeByItemId[itemId] ?? 0;
        final createdAt = getStringFromRow(item, 'created_at');

        // 입찰 내역과 동일한 규칙으로 상태 문자열 생성
        String status;
        if (tradeCode == 550) {
          status = '거래 완료';
        } else if (tradeCode == TradeStatusCode.shippingInfoRequired) {
          // 배송 정보가 있으면 "배송 중", 없으면 "결제 완료"
          status = itemIdsWithShipping.contains(itemId) ? '배송 중' : '결제 완료';
        } else if (tradeCode == TradeStatusCode.paymentRequired) {
          status = '결제 대기';
        } else {
          switch (auctionCode) {
            case AuctionStatusCode.ready:
              status = '경매 대기';
              break;
            case AuctionStatusCode.inProgress:
              status = '경매 진행 중';
              break;
            case AuctionStatusCode.instantBuyPaymentPending:
              status = '즉시 구매 진행 중';
              break;
            case AuctionStatusCode.bidWon:
              status = '입찰 낙찰';
              break;
            case AuctionStatusCode.instantBuyCompleted:
              status = '즉시 구매 완료';
              break;
            case AuctionStatusCode.failed:
              status = '유찰';
              break;
            default:
              status = '';
          }
        }

        return SaleHistoryItem(
          itemId: itemId,
          title: getStringFromRow(item, 'title'),
          price: priceByItemId[itemId] ?? 0,
          thumbnailUrl: getNullableStringFromRow(item, 'thumbnail_image'),
          status: status,
          date: formatDateTimeFromIso(createdAt),
          tradeStatusCode: tradeCode == 0 ? null : tradeCode,
          auctionStatusCode: auctionCode,
          hasShippingInfo: itemIdsWithShipping.contains(itemId),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}