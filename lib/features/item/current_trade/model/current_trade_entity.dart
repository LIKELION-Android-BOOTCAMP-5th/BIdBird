import 'package:bidbird/features/item/model/trade_status_codes.dart';

enum TradeItemStatus {
  todo, // 지금 필요한 처리
  inProgress, // 배송 중 / 처리 중
  completed, // 완료
}

enum TradeActionType {
  paymentRequired, // 결제하러 가기 (구매자용)
  paymentWaiting, // 결제 대기 (판매자용)
  shippingInfoRequired, // 배송지 입력 필요
  purchaseConfirmRequired, // 구매 확정
  none, // 액션 없음
}

/// 거래 아이템의 공통 인터페이스
abstract class TradeHistoryItem {
  TradeItemStatus get itemStatus;
  TradeActionType get actionType;
}

class BidHistoryItem implements TradeHistoryItem {
  final String itemId;
  final String title;
  final int price;
  final String? thumbnailUrl;
  final String status;
  final int? tradeStatusCode;
  final int? auctionStatusCode;
  final bool hasShippingInfo;

  BidHistoryItem({
    required this.itemId,
    required this.title,
    required this.price,
    this.thumbnailUrl,
    required this.status,
    this.tradeStatusCode,
    this.auctionStatusCode,
    this.hasShippingInfo = false,
  });

  /// 상태 분류 (지금 필요한 처리 / 배송 중 / 처리 중 / 완료)
  TradeItemStatus get itemStatus {
    // 구매자: 결제 대기 (510), 구매 확정 (520이고 배송 완료)
    if (tradeStatusCode == TradeStatusCode.paymentRequired) {
      return TradeItemStatus.todo;
    }
    // 완료: 550
    if (tradeStatusCode == TradeStatusCode.completed) {
      return TradeItemStatus.completed;
    }
    // 배송 중 / 처리 중: 나머지
    return TradeItemStatus.inProgress;
  }

  /// 필요한 액션 타입
  TradeActionType get actionType {
    // 구매자: 결제 대기
    if (tradeStatusCode == TradeStatusCode.paymentRequired) {
      return TradeActionType.paymentRequired;
    }
    // 구매 확정 (520이고 배송 정보 있음)
    if (tradeStatusCode == TradeStatusCode.shippingInfoRequired && hasShippingInfo) {
      return TradeActionType.purchaseConfirmRequired;
    }
    return TradeActionType.none;
  }
}

class SaleHistoryItem implements TradeHistoryItem {
  final String itemId;
  final String title;
  final int price;
  final String? thumbnailUrl;
  final String status;
  final String date;
  final int? tradeStatusCode;
  final int? auctionStatusCode;
  final bool hasShippingInfo;

  SaleHistoryItem({
    required this.itemId,
    required this.title,
    required this.price,
    this.thumbnailUrl,
    required this.status,
    required this.date,
    this.tradeStatusCode,
    this.auctionStatusCode,
    this.hasShippingInfo = false,
  });

  /// 상태 분류 (지금 필요한 처리 / 배송 중 / 처리 중 / 완료)
  TradeItemStatus get itemStatus {
    // 판매자: 배송지 입력 필요 (520이고 배송 정보 없음)
    if (tradeStatusCode == TradeStatusCode.shippingInfoRequired && !hasShippingInfo) {
      return TradeItemStatus.todo;
    }
    // 완료: 550
    if (tradeStatusCode == TradeStatusCode.completed) {
      return TradeItemStatus.completed;
    }
    // 배송 중 / 처리 중: 나머지
    return TradeItemStatus.inProgress;
  }

  /// 필요한 액션 타입
  TradeActionType get actionType {
    // 판매자: 결제 대기 (510) - 판매자는 결제를 받는 입장이므로 paymentWaiting
    if (tradeStatusCode == TradeStatusCode.paymentRequired) {
      return TradeActionType.paymentWaiting;
    }
    // 판매자: 배송지 입력 필요 (520이고 배송 정보 없음)
    if (tradeStatusCode == TradeStatusCode.shippingInfoRequired && !hasShippingInfo) {
      return TradeActionType.shippingInfoRequired;
    }
    return TradeActionType.none;
  }
}

/// 액션 허브 아이템
class ActionHubItem {
  ActionHubItem({
    required this.actionType,
    required this.count,
  });

  final TradeActionType actionType;
  final int count;

  String get label {
    switch (actionType) {
      case TradeActionType.paymentRequired:
        return '결제하러 가기';
      case TradeActionType.paymentWaiting:
        return '결제 대기';
      case TradeActionType.shippingInfoRequired:
        return '배송지 입력';
      case TradeActionType.purchaseConfirmRequired:
        return '구매 확정';
      case TradeActionType.none:
        return '';
    }
  }
}


