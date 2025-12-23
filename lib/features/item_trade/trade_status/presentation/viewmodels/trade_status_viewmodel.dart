import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/item_trade/trade_status/data/repositories/trade_status_repository.dart';
import 'package:bidbird/features/item_trade/trade_status/domain/entities/trade_status_entity.dart';
import 'package:bidbird/features/item_trade/trade_status/domain/usecases/fetch_trade_status_usecase.dart';
import 'package:flutter/material.dart';

/// TradeStatus ViewModel - Thin Pattern
/// 책임: 거래 상태 UI 상태 관리, UseCase 호출
/// 제외: 비즈니스 로직 (UseCase에서 처리)
class TradeStatusViewModel extends ItemBaseViewModel {
  final String itemId;
  final FetchTradeStatusUseCase _fetchTradeStatusUseCase;
  
  // State: UI Status
  bool _isRefreshing = false;

  TradeStatusViewModel({
    required this.itemId,
    FetchTradeStatusUseCase? fetchTradeStatusUseCase,
  })  : _fetchTradeStatusUseCase =
            fetchTradeStatusUseCase ?? FetchTradeStatusUseCase(TradeStatusRepositoryImpl()) {
    setLoading(true);
  }

  // State: Trade Data
  TradeStatusEntity? _tradeStatus;

  TradeStatusEntity? get tradeStatus => _tradeStatus;

  // Computed
  bool get isSeller {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    return currentUserId != null &&
        _tradeStatus?.itemInfo != null &&
        _tradeStatus!.itemInfo!.sellerId == currentUserId;
  }

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

  String get currentStatusText {
    // 거래 완료 상태를 우선 확인
    if (_tradeStatus?.tradeInfo != null &&
        _tradeStatus!.tradeInfo!.tradeStatusCode == TradeStatusCode.completed) {
      return '거래 완료';
    }
    
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

  DateTime? get paymentDeadline {
    final auctionInfo = _tradeStatus?.auctionInfo;
    if (auctionInfo == null || auctionInfo.auctionEndAt.isEmpty) {
      return null;
    }

    try {
      final auctionEndAt = DateTime.parse(auctionInfo.auctionEndAt);
      return auctionEndAt.add(const Duration(hours: 24));
    } catch (e) {
      debugPrint('결제 기한 계산 에러: $e');
      return null;
    }
  }

  bool shouldShowActionButton() {
    final step = currentStep;
    if (step == TradeStep.payment && !isSeller) {
      return true;
    }
    if (step == TradeStep.shipping && isSeller) {
      return true;
    }
    return false;
  }

  // Methods: Data Loading
  Future<void> loadData() async {
    if (isLoading) return;
    startLoading();

    try {
      _tradeStatus = await _fetchTradeStatusUseCase(itemId);
      
      if (_tradeStatus?.tradeInfo == null) {
        stopLoadingWithError('거래 정보가 없습니다.');
        return;
      }
      
      stopLoading();
    } catch (e) {
      stopLoadingWithError(e.toString());
    }
  }

  Future<void> refreshShippingInfo() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      _tradeStatus = await _fetchTradeStatusUseCase(itemId);
      notifyListeners();
    } catch (e) {
      debugPrint('송장 정보 재로드 에러: $e');
    } finally {
      _isRefreshing = false;
    }
  }
}

