import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/item_trade/trade_status/data/repositories/trade_status_repository.dart';
import 'package:bidbird/features/item_trade/trade_status/domain/entities/trade_status_entity.dart';
import 'package:bidbird/features/item_trade/trade_status/domain/usecases/fetch_trade_status_usecase.dart';
import 'package:flutter/material.dart';

class TradeStatusViewModel extends ItemBaseViewModel {
  final String itemId;
  final FetchTradeStatusUseCase _fetchTradeStatusUseCase;
  bool _isRefreshing = false; // 중복 요청 방지

  TradeStatusViewModel({
    required this.itemId,
    FetchTradeStatusUseCase? fetchTradeStatusUseCase,
  })  : _fetchTradeStatusUseCase =
            fetchTradeStatusUseCase ?? FetchTradeStatusUseCase(TradeStatusRepositoryImpl()) {
    // 초기 로딩 상태 설정
    setLoading(true);
  }

  TradeStatusEntity? _tradeStatus;

  TradeStatusEntity? get tradeStatus => _tradeStatus;

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
    if (isLoading) return; // 중복 로드 방지
    startLoading();

    try {
      _tradeStatus = await _fetchTradeStatusUseCase(itemId);
      
      // 거래 정보(tradeInfo)가 없으면 에러 처리
      if (_tradeStatus?.tradeInfo == null) {
        stopLoadingWithError('거래 정보가 없습니다.');
        return;
      }
      
      stopLoading();
    } catch (e) {
      stopLoadingWithError(e.toString());
    }
  }

  /// 송장 정보 업데이트 후 재로드
  Future<void> refreshShippingInfo() async {
    if (_isRefreshing) return; // 중복 요청 방지
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

