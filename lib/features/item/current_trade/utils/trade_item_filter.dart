import 'package:bidbird/features/item/model/trade_status_codes.dart';
import '../model/current_trade_entity.dart';

/// 거래 아이템 필터링 유틸리티
class TradeItemFilter {
  TradeItemFilter._();

  /// 판매 아이템이 포함되어야 하는지 확인
  static bool shouldIncludeSaleItem(
    SaleHistoryItem item,
    List<TradeActionType> targetActionTypes,
  ) {
    // actionType이 none이 아니고 targetActionTypes에 포함되면 포함
    if (item.actionType != TradeActionType.none && 
        targetActionTypes.contains(item.actionType)) {
      return true;
    }
    // actionType이 none이면 tradeStatusCode로 직접 판단
    if (item.actionType == TradeActionType.none) {
      if (item.tradeStatusCode == TradeStatusCode.paymentRequired && 
          targetActionTypes.contains(TradeActionType.paymentWaiting)) {
        return true;
      }
      if (item.tradeStatusCode == TradeStatusCode.shippingInfoRequired && 
          !item.hasShippingInfo &&
          targetActionTypes.contains(TradeActionType.shippingInfoRequired)) {
        return true;
      }
    }
    return false;
  }

  /// 입찰 아이템이 포함되어야 하는지 확인
  static bool shouldIncludeBidItem(
    BidHistoryItem item,
    List<TradeActionType> targetActionTypes,
  ) {
    // actionType이 none이 아니고 targetActionTypes에 포함되면 포함
    if (item.actionType != TradeActionType.none && 
        targetActionTypes.contains(item.actionType)) {
      return true;
    }
    // actionType이 none이면 tradeStatusCode로 직접 판단
    if (item.actionType == TradeActionType.none) {
      if (item.tradeStatusCode == TradeStatusCode.paymentRequired && 
          targetActionTypes.contains(TradeActionType.paymentRequired)) {
        return true;
      }
      if (item.tradeStatusCode == TradeStatusCode.shippingInfoRequired && 
          item.hasShippingInfo &&
          targetActionTypes.contains(TradeActionType.purchaseConfirmRequired)) {
        return true;
      }
    }
    // auction_status_code=321이고 tradeStatusCode가 없으면 결제 대기
    if ((item.tradeStatusCode == null || item.tradeStatusCode == 0) &&
        item.auctionStatusCode == AuctionStatusCode.bidWon &&
        targetActionTypes.contains(TradeActionType.paymentRequired)) {
      return true;
    }
    return false;
  }

  /// 판매 아이템의 액션 타입 결정
  static TradeActionType? determineSaleItemActionType(SaleHistoryItem item) {
    if (item.actionType != TradeActionType.none) {
      return item.actionType;
    }
    if (item.tradeStatusCode == TradeStatusCode.paymentRequired) {
      return TradeActionType.paymentWaiting; // 판매자는 paymentWaiting
    } else if (item.tradeStatusCode == TradeStatusCode.shippingInfoRequired && 
               !item.hasShippingInfo) {
      return TradeActionType.shippingInfoRequired;
    }
    return null;
  }

  /// 입찰 아이템의 액션 타입 결정
  static TradeActionType? determineBidItemActionType(BidHistoryItem item) {
    if (item.actionType != TradeActionType.none) {
      return item.actionType;
    }
    if (item.tradeStatusCode == TradeStatusCode.paymentRequired) {
      return TradeActionType.paymentRequired;
    } else if (item.tradeStatusCode == TradeStatusCode.shippingInfoRequired && 
               item.hasShippingInfo) {
      return TradeActionType.purchaseConfirmRequired;
    } else if ((item.tradeStatusCode == null || item.tradeStatusCode == 0) &&
               item.auctionStatusCode == AuctionStatusCode.bidWon) {
      return TradeActionType.paymentRequired;
    }
    return null;
  }

  /// 액션 타입별로 아이템 그룹화
  static Map<TradeActionType, List<dynamic>> groupItemsByActionType({
    required List<SaleHistoryItem> saleItems,
    required List<BidHistoryItem> bidItems,
    required List<TradeActionType> targetActionTypes,
  }) {
    final Map<TradeActionType, List<dynamic>> itemsByActionType = {};
    
    // 각 액션 타입별로 아이템 수집
    for (final actionType in targetActionTypes) {
      itemsByActionType[actionType] = [];
    }
    
    // 판매 아이템 분류
    for (final item in saleItems) {
      final itemActionType = determineSaleItemActionType(item);
      if (itemActionType != null && itemsByActionType.containsKey(itemActionType)) {
        itemsByActionType[itemActionType]!.add(item);
      }
    }
    
    // 입찰 아이템 분류
    for (final item in bidItems) {
      final itemActionType = determineBidItemActionType(item);
      if (itemActionType != null && itemsByActionType.containsKey(itemActionType)) {
        itemsByActionType[itemActionType]!.add(item);
      }
    }
    
    return itemsByActionType;
  }
}


