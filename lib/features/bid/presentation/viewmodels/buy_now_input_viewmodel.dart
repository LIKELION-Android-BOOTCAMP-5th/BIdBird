import 'package:flutter/material.dart';

import 'package:bidbird/features/bid/domain/usecases/place_buy_now_bid_usecase.dart';
import 'package:bidbird/features/bid/domain/usecases/check_bid_restriction_usecase.dart';
import 'package:bidbird/features/bid/data/repositories/bid_repository.dart';

class BuyNowInputViewModel extends ChangeNotifier {
  BuyNowInputViewModel({
    PlaceBuyNowBidUseCase? placeBuyNowBidUseCase,
    CheckBidRestrictionUseCase? checkBidRestrictionUseCase,
  })  : _placeBuyNowBidUseCase =
            placeBuyNowBidUseCase ?? PlaceBuyNowBidUseCase(BidRepositoryImpl()),
        _checkBidRestrictionUseCase = checkBidRestrictionUseCase ??
            CheckBidRestrictionUseCase(BidRepositoryImpl());

  // ignore: unused_field
  final PlaceBuyNowBidUseCase _placeBuyNowBidUseCase;
  final CheckBidRestrictionUseCase _checkBidRestrictionUseCase;

  bool isSubmitting = false;

  Future<bool> checkBidRestriction() {
    return _checkBidRestrictionUseCase();
  }

  // 임시로 주석 처리: 결제 비활성화
  /*
  Future<void> placeBid({
    required String itemId,
    required int bidPrice,
  }) async {
    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final request = BuyNowBidRequest(
        itemId: itemId,
        bidPrice: bidPrice,
      );
      await _placeBuyNowBidUseCase(request);
    } catch (e) {
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
  */

  Future<void> Temporary_bid({
    required String itemId,
    required int bidPrice,
  }) async {
    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    try {
      // 임시 코드: 사용자끼리 거래, 채팅 시작 또는 알림
      print('임시 입찰: itemId $itemId, bidPrice $bidPrice');
      // 실제로는 채팅으로 연결하는 로직 추가
    } catch (e) {
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
