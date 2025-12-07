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
          .select(
              'item_id, text_code, int_code, winner_id, current_highest_bidder')
          .inFilter('item_id', itemIds);

      final Map<String, String> statusByItemId = {};
      final Map<String, int> intStatusByItemId = {};
      final Map<String, String> winnerByItemId = {};
      final Map<String, String> highestByItemId = {};
      for (final row in statusRowsForItems) {
        final id = row['item_id']?.toString();
        if (id != null) {
          statusByItemId[id] = row['text_code']?.toString() ?? '';
          intStatusByItemId[id] = (row['int_code'] as int?) ?? 0;
          winnerByItemId[id] = row['winner_id']?.toString() ?? '';
          highestByItemId[id] =
              row['current_highest_bidder']?.toString() ?? '';
        }
      }

      return bids.map((row) {
        final itemId = row['item_id']?.toString() ?? '';
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final bidPrice = row['bid_price'] as int? ?? 0;
        final currentPrice = item['current_price'] as int? ?? 0;
        final rawStatus = statusByItemId[itemId] ?? '';
        final intStatus = intStatusByItemId[itemId] ?? 0;
        final winnerId = winnerByItemId[itemId] ?? '';
        final highestId = highestByItemId[itemId] ?? '';

        // bid_log.status 코드 (예: 1001 NORMAL_SUCCESS, 2001 LOWER_THAN_CURRENT 등)를 해석
        final statusCode = int.tryParse(row['status']?.toString() ?? '');

        String? logStatus;
        switch (statusCode) {
          case 1001: // NORMAL_SUCCESS
            logStatus = '입찰 성공';
            break;
          case 2001: // LOWER_THAN_CURRENT
            logStatus = '현재가보다 낮은 입찰';
            break;
          case 2002: // AUCTION_CLOSED
            logStatus = '경매 종료 후 입찰';
            break;
          case 2003: // ITEM_LOCKED
            logStatus = '거래정지 상품';
            break;
          case 3001: // PAYMENT_FAIL
            logStatus = '결제 실패';
            break;
          case 3002: // PAYMENT_FAILURE_LIMIT
            logStatus = '결제 실패 횟수 초과';
            break;
        }

        String displayStatus;
        if (logStatus != null && logStatus.isNotEmpty) {
          // 로그 상태 코드가 정의돼 있으면 우선 사용 (결제 실패 등)
          displayStatus = logStatus;
        } else {
          // 경매 종료 여부 + winner_id / current_highest_bidder 기반으로 상태 결정
          final bool isAuctionEnded =
              intStatus == 1008 || intStatus == 1009 || intStatus == 1010;
          final bool isWinner = winnerId.isNotEmpty && winnerId == user.id;
          final bool hasHighestBid = highestId.isNotEmpty && highestId == user.id;

          if (rawStatus.contains('입찰 제한') || rawStatus.contains('거래정지')) {
            displayStatus = '거래정지';
          } else if (isAuctionEnded) {
            // 경매가 끝난 경우 (구매자 관점에서는 낙찰 또는 패찰만 구분)
            if (isWinner) {
              displayStatus = '낙찰';
            } else {
              // 유찰(1010) 포함, 내가 낙찰자가 아니면 모두 패찰로 표기
              displayStatus = '패찰';
            }
          } else {
            // 경매 진행 중인 경우: 최고가 입찰 / 상위 입찰됨
            if (hasHighestBid) {
              displayStatus = '최고가 입찰';
            } else {
              displayStatus = '상회 입찰';
            }
          }
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
        final rawStatus = row['text_code']?.toString() ?? '';
        final intCode = row['int_code'] as int? ?? 0;
        final createdAt = row['update_at']?.toString() ?? '';

        // bid_status.int_code 기준으로 한글 라벨을 매핑
        String displayStatus;
        switch (intCode) {
          case 1001: // 경매 대기
            displayStatus = '경매 대기';
            break;
          case 1002: // 경매 등록
            displayStatus = '경매 등록';
            break;
          case 1003: // 입찰 발생
            displayStatus = '입찰 발생';
            break;
          case 1005: // 상위입찰 발생
            displayStatus = '상위 입찰 발생';
            break;
          case 1006: // 즉시 구매 대기
            displayStatus = '즉시 구매 대기';
            break;
          case 1007: // 즉시 구매 완료
            displayStatus = '즉시 구매 완료';
            break;
          case 1008: // 즉시 구매 실패
            displayStatus = '즉시 구매 실패';
            break;
          case 1009: // 경매 종료 - 낙찰
            displayStatus = '경매 종료 - 낙찰';
            break;
          case 1010: // 경매 종료 - 유찰
            displayStatus = '경매 종료 - 유찰';
            break;
          case 1011: // 경매 정지 - 신고
            displayStatus = '경매 정지 - 신고';
            break;
          default:
            // 정의되지 않은 코드는 text_code 그대로 사용
            displayStatus = rawStatus;
            break;
        }

        return SaleHistoryItem(
          itemId: itemId,
          title: item['title']?.toString() ?? '',
          price: (item['current_price'] as int?) ?? 0,
          thumbnailUrl: item['thumbnail_image']?.toString(),
          status: displayStatus,
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