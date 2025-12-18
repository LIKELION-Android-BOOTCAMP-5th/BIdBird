import 'package:flutter/material.dart';

import 'package:bidbird/features/bid/domain/entities/bid_request_entity.dart';
import 'package:bidbird/features/bid/domain/usecases/place_bid_usecase.dart';
import 'package:bidbird/features/bid/data/repositories/bid_repository.dart';

class PriceInputViewModel extends ChangeNotifier {
  PriceInputViewModel({PlaceBidUseCase? placeBidUseCase})
      : _placeBidUseCase =
            placeBidUseCase ?? PlaceBidUseCase(BidRepositoryImpl());

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



