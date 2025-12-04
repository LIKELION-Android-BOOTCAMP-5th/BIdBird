import 'package:flutter/material.dart';

import '../data/repository/price_input_repository.dart';
import '../model/price_input_entity.dart';

class PriceInputViewModel extends ChangeNotifier {
  PriceInputViewModel({PriceInputRepository? repository})
      : _repository = repository ?? PriceInputRepository();

  final PriceInputRepository _repository;

  bool isSubmitting = false;

  Future<void> placeBid({
    required String itemId,
    required int bidPrice,
  }) async {
    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final request = BidRequest(itemId: itemId, bidPrice: bidPrice);
      await _repository.placeBid(request);
    } catch (e) {
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}