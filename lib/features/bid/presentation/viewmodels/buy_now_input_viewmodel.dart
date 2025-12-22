import 'package:flutter/material.dart';

import 'package:bidbird/features/bid/domain/entities/buy_now_bid_request_entity.dart';
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

  final PlaceBuyNowBidUseCase _placeBuyNowBidUseCase;
  final CheckBidRestrictionUseCase _checkBidRestrictionUseCase;

  bool isSubmitting = false;

  Future<bool> checkBidRestriction() {
    return _checkBidRestrictionUseCase();
  }

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
}
