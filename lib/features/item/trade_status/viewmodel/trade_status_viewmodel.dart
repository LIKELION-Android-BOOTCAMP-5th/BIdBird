import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/model/trade_status_codes.dart';
import 'package:bidbird/features/item/trade_status/data/repository/trade_status_repository.dart';
import 'package:bidbird/features/item/trade_status/model/trade_status_entity.dart';
import 'package:flutter/material.dart';

class TradeStatusViewModel extends ChangeNotifier {
  final String itemId;
  final TradeStatusRepository _repository;

  TradeStatusViewModel({
    required this.itemId,
    TradeStatusRepository? repository,
  }) : _repository = repository ?? TradeStatusRepositoryImpl();

  TradeStatusEntity? _tradeStatus;
  bool _isLoading = true;
  String? _error;

  TradeStatusEntity? get tradeStatus => _tradeStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 현재 사용자가 판매자인지 확인
  bool get isSeller {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    return currentUserId != null &&
        _tradeStatus?.itemInfo != null &&
        _tradeStatus!.itemInfo!.sellerId == currentUserId;
  }

  /// 현재 단계 확인
  TradeStep get currentStep {
    if (_tradeStatus?.tradeInfo != null) {
      switch (_tradeStatus!.tradeInfo!.tradeStatusCode) {
        case TradeStatusCode.paymentRequired:
          return TradeStep.payment;
        case TradeStatusCode.shippingInfoRequired:
          return TradeStep.shipping;
        case TradeStatusCode.completed:
          return TradeStep.completed;
        default:
          break;
      }
    }

    if (_tradeStatus?.auctionInfo != null) {
      final auctionInfo = _tradeStatus!.auctionInfo!;
      if (auctionInfo.auctionStatusCode == AuctionStatusCode.bidWon ||
          auctionInfo.auctionStatusCode ==
              AuctionStatusCode.instantBuyCompleted) {
        return TradeStep.won;
      }
      if (auctionInfo.auctionStatusCode == AuctionStatusCode.inProgress ||
          auctionInfo.auctionStatusCode ==
              AuctionStatusCode.instantBuyPaymentPending) {
        return TradeStep.bidding;
      }
    }

    return TradeStep.bidding;
  }

  /// 현재 상태 텍스트
  String get currentStatusText {
    final step = currentStep;
    switch (step) {
      case TradeStep.bidding:
        return '입찰 중';
      case TradeStep.won:
        return '낙찰 완료';
      case TradeStep.payment:
        return '결제 대기';
      case TradeStep.shipping:
        return '배송 중';
      case TradeStep.completed:
        return '거래 완료';
    }
  }

  /// 결제 기한 계산 (auction_end_at + 24시간)
  DateTime? get paymentDeadline {
    final auctionInfo = _tradeStatus?.auctionInfo;
    if (auctionInfo == null || auctionInfo.auctionEndAt.isEmpty) {
      return null;
    }

    try {
      final auctionEndAt = DateTime.parse(auctionInfo.auctionEndAt);
      // auction_end_at + 24시간
      return auctionEndAt.add(const Duration(hours: 24));
    } catch (e) {
      debugPrint('결제 기한 계산 에러: $e');
      return null;
    }
  }

  /// 액션 버튼 표시 여부
  bool shouldShowActionButton() {
    final step = currentStep;
    // 결제 단계에서 구매자에게 버튼 표시
    if (step == TradeStep.payment && !isSeller) {
      return true;
    }
    // 배송 단계에서 판매자에게 버튼 표시
    if (step == TradeStep.shipping && isSeller) {
      return true;
    }
    return false;
  }

  /// 데이터 로드
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tradeStatus = await _repository.fetchTradeStatus(itemId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 송장 정보 업데이트 후 재로드
  Future<void> refreshShippingInfo() async {
    try {
      _tradeStatus = await _repository.fetchTradeStatus(itemId);
      notifyListeners();
    } catch (e) {
      debugPrint('송장 정보 재로드 에러: $e');
    }
  }
}

