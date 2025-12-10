import 'package:flutter/material.dart';

import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/buy_now_input_entity.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/place_buy_now_bid_usecase.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/check_bid_restriction_usecase.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/data/repository/buy_now_input_repository.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/data/repository/bid_restriction_gateway_impl.dart';

class BuyNowInputViewModel extends ChangeNotifier {
  BuyNowInputViewModel({
    PlaceBuyNowBidUseCase? placeBuyNowBidUseCase,
    CheckBidRestrictionUseCase? checkBidRestrictionUseCase,
  })  : _placeBuyNowBidUseCase =
            placeBuyNowBidUseCase ?? PlaceBuyNowBidUseCase(BuyNowInputGatewayImpl()),
        _checkBidRestrictionUseCase = checkBidRestrictionUseCase ??
            CheckBidRestrictionUseCase(BidRestrictionGatewayImpl());

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
