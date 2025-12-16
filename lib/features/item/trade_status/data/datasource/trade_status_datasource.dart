import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart' as domain;
import 'package:bidbird/features/item/model/trade_status_codes.dart';
import 'package:bidbird/features/item/trade_status/model/trade_status_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TradeStatusDatasource {
  TradeStatusDatasource({
    SupabaseClient? supabase,
    domain.ChatRepository? chatRepository,
  })  : _supabase = supabase ?? SupabaseManager.shared.supabase,
        _chatRepository = chatRepository ?? ChatRepositoryImpl();

  final SupabaseClient _supabase;
  final domain.ChatRepository _chatRepository;

  /// 거래 현황 정보 조회
  Future<TradeStatusEntity> fetchTradeStatus(String itemId) async {
    final roomInfo = await _chatRepository.fetchRoomInfo(itemId);

    if (roomInfo == null) {
      throw Exception('거래 정보를 불러올 수 없습니다.');
    }

    final itemInfo = roomInfo.item;
    final auctionInfo = roomInfo.auction;
    final tradeInfo = roomInfo.trade;

    // 거래 기록 로드
    final historyEvents = await _loadTradeHistory(
      itemId,
      auctionInfo,
      itemInfo,
      tradeInfo,
    );

    // 송장 정보 로드 (배송 단계일 때)
    Map<String, dynamic>? shippingInfo;
    if (tradeInfo != null &&
        tradeInfo.tradeStatusCode == TradeStatusCode.shippingInfoRequired) {
      try {
        shippingInfo = await _getShippingInfo(itemId);
      } catch (e) {
        print('송장 정보 로드 에러: $e');
      }
    }

    return TradeStatusEntity(
      itemInfo: itemInfo,
      auctionInfo: auctionInfo,
      tradeInfo: tradeInfo,
      historyEvents: historyEvents,
      shippingInfo: shippingInfo,
    );
  }

  /// 송장 정보 조회
  Future<Map<String, dynamic>?> _getShippingInfo(String itemId) async {
    try {
      final result = await _supabase
          .from('shipping_info')
          .select('carrier, tracking_number')
          .eq('item_id', itemId)
          .maybeSingle();

      return result;
    } catch (e) {
      print('송장 정보 조회 에러: $e');
      return null;
    }
  }

  /// 거래 기록 로드
  Future<List<TradeHistoryEvent>> _loadTradeHistory(
    String itemId,
    AuctionInfoEntity? auctionInfo,
    ItemInfoEntity? itemInfo,
    TradeInfoEntity? tradeInfo,
  ) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final events = <TradeHistoryEvent>[];

      // 1. 거래 시작 (아이템 생성일)
      if (itemInfo != null) {
        try {
          final itemRow = await _supabase
              .from('items_detail')
              .select('created_at')
              .eq('item_id', itemId)
              .maybeSingle();

          final createdAt = itemRow != null && itemRow['created_at'] != null
              ? DateTime.parse(itemRow['created_at'])
              : DateTime.now();

          final sellerInfo = await _supabase
              .from('users')
              .select('nick_name')
              .eq('id', itemInfo.sellerId)
              .maybeSingle();

          events.add(TradeHistoryEvent(
            type: TradeEventType.tradeStarted,
            title: '거래 시작',
            actor: sellerInfo?['nick_name'] as String? ?? '판매자',
            actorType: '판매자',
            timestamp: createdAt,
            isActive: false,
          ));
        } catch (e) {
          print('거래 시작 이벤트 추가 에러: $e');
          events.add(TradeHistoryEvent(
            type: TradeEventType.tradeStarted,
            title: '거래 시작',
            actor: '판매자',
            actorType: '판매자',
            timestamp: DateTime.now(),
            isActive: false,
          ));
        }
      }

      // 2. 입찰 기록
      if (auctionInfo != null) {
        final bidLogs = await _supabase
            .from('auctions_status_log')
            .select('bid_price, created_at, user_id, auction_log_code')
            .eq('bid_status_id', auctionInfo.auctionId)
            .neq('bid_price', 0)
            .order('created_at', ascending: false)
            .limit(10);

        for (final log in bidLogs) {
          if (log['user_id'] == currentUserId) {
            final bidderInfo = await _supabase
                .from('users')
                .select('nick_name')
                .eq('id', log['user_id'])
                .maybeSingle();

            events.add(TradeHistoryEvent(
              type: TradeEventType.bidParticipated,
              title: '입찰 참여',
              subtitle: '${formatPrice(log['bid_price'] as int)}원',
              actor: bidderInfo?['nick_name'] as String? ?? '구매자',
              actorType: '구매자',
              timestamp: DateTime.parse(log['created_at']),
              isActive: false,
            ));
            break; // 가장 최근 입찰만 표시
          }
        }

        // 3. 경매 종료 (경매가 종료된 경우)
        if (auctionInfo.auctionEndAt.isNotEmpty) {
          try {
            final endAt = DateTime.parse(auctionInfo.auctionEndAt);
            events.add(TradeHistoryEvent(
              type: TradeEventType.auctionEnded,
              title: '경매 종료',
              actor: '시스템',
              actorType: '시스템',
              timestamp: endAt,
              isActive: false,
            ));
          } catch (e) {
            print('경매 종료 시간 파싱 에러: $e');
          }
        }

        // 4. 낙찰 성공 (판매자/구매자 모두에게 표시)
        if (auctionInfo.auctionStatusCode == AuctionStatusCode.bidWon &&
            auctionInfo.lastBidUserId != null) {
          final bidderInfo = await _supabase
              .from('users')
              .select('nick_name')
              .eq('id', auctionInfo.lastBidUserId!)
              .maybeSingle();

          final isCurrentUserWinner = auctionInfo.lastBidUserId == currentUserId;

          events.add(TradeHistoryEvent(
            type: TradeEventType.bidWon,
            title: isCurrentUserWinner ? '낙찰 성공' : '낙찰 완료',
            actor: bidderInfo?['nick_name'] as String? ?? '구매자',
            actorType: '구매자',
            timestamp: auctionInfo.auctionEndAt.isNotEmpty
                ? DateTime.parse(auctionInfo.auctionEndAt)
                : DateTime.now(),
            isActive: isCurrentUserWinner,
          ));
        }
      }

      // 5. 결제 완료
      if (tradeInfo != null && tradeInfo.paidAt != null) {
        final buyerInfo = await _supabase
            .from('users')
            .select('nick_name')
            .eq('id', tradeInfo.buyerId)
            .maybeSingle();

        events.add(TradeHistoryEvent(
          type: TradeEventType.paymentCompleted,
          title: '결제 완료',
          actor: buyerInfo?['nick_name'] as String? ?? '구매자',
          actorType: '구매자',
          timestamp: DateTime.parse(tradeInfo.paidAt!),
          isActive: false,
        ));
      }

      // 6. 배송 시작
      if (tradeInfo != null && tradeInfo.shippingStartAt != null) {
        final sellerInfo = await _supabase
            .from('users')
            .select('nick_name')
            .eq('id', tradeInfo.sellerId)
            .maybeSingle();

        events.add(TradeHistoryEvent(
          type: TradeEventType.shippingStarted,
          title: '배송 시작',
          actor: sellerInfo?['nick_name'] as String? ?? '판매자',
          actorType: '판매자',
          timestamp: DateTime.parse(tradeInfo.shippingStartAt!),
          isActive: false,
        ));
      }

      // 7. 배송 완료
      if (tradeInfo != null && tradeInfo.shippingCompletedAt != null) {
        events.add(TradeHistoryEvent(
          type: TradeEventType.shippingCompleted,
          title: '배송 완료',
          actor: '시스템',
          actorType: '시스템',
          timestamp: DateTime.parse(tradeInfo.shippingCompletedAt!),
          isActive: false,
        ));
      }

      // 시간순 정렬 (오래된 것부터)
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return events;
    } catch (e, stackTrace) {
      print('거래 기록 로드 중 에러: $e');
      print('스택 트레이스: $stackTrace');
      return [];
    }
  }
}

