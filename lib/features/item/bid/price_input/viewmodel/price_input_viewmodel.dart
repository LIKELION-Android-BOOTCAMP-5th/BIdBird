import 'package:flutter/material.dart';

import 'package:bidbird/features/item/bid/price_input/model/bottom_sheet_price_input_entity.dart';
import 'package:bidbird/features/item/bid/price_input/usecase/place_bid_usecase.dart';
import 'package:bidbird/features/item/bid/price_input/data/repository/bid_input_gateway_impl.dart';

class PriceInputViewModel extends ChangeNotifier {
  PriceInputViewModel({PlaceBidUseCase? placeBidUseCase})
      : _placeBidUseCase =
            placeBidUseCase ?? PlaceBidUseCase(BidInputGatewayImpl());

  final PlaceBidUseCase _placeBidUseCase;

  bool isSubmitting = false;

  Future<void> placeBid({
    required String itemId,
    required int bidPrice,
    bool isInstant = false,
  }) async {
    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final request = BidRequest(
        itemId: itemId,
        bidPrice: bidPrice,
        isInstant: isInstant,
      );
      await _placeBidUseCase(request);
    } catch (e) {
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}