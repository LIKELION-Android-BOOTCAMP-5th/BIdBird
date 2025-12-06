import 'package:flutter/material.dart';

import 'package:bidbird/features/item/bottom_sheet_buy_now_input/data/repository/buy_now_input_repository.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/buy_now_input_entity.dart';

class BuyNowInputViewModel extends ChangeNotifier {
  BuyNowInputViewModel({BuyNowInputRepository? repository})
      : _repository = repository ?? BuyNowInputRepository();

  final BuyNowInputRepository _repository;

  bool isSubmitting = false;

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
      await _repository.placeBid(request);
    } catch (e) {
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
