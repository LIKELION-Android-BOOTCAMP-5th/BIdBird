import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';

/// 거래 현황 정보
class TradeStatusEntity {
  final ItemInfoEntity? itemInfo;
  final AuctionInfoEntity? auctionInfo;
  final TradeInfoEntity? tradeInfo;
  final List<TradeHistoryEvent> historyEvents;
  final Map<String, dynamic>? shippingInfo;

  TradeStatusEntity({
    this.itemInfo,
    this.auctionInfo,
    this.tradeInfo,
    required this.historyEvents,
    this.shippingInfo,
  });
}

/// 거래 단계
enum TradeStep {
  bidding, // 입찰
  won, // 낙찰
  payment, // 결제
  shipping, // 배송
  completed, // 완료
}

/// 거래 이벤트 타입
enum TradeEventType {
  tradeStarted,
  bidParticipated,
  auctionEnded,
  bidWon,
  paymentCompleted,
  shippingStarted,
  shippingCompleted,
}

/// 거래 기록 이벤트
class TradeHistoryEvent {
  final TradeEventType type;
  final String title;
  final String? subtitle;
  final String actor;
  final String actorType;
  final DateTime timestamp;
  final bool isActive;

  TradeHistoryEvent({
    required this.type,
    required this.title,
    this.subtitle,
    required this.actor,
    required this.actorType,
    required this.timestamp,
    this.isActive = false,
  });
}

