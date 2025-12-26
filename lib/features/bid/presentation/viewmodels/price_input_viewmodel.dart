import 'package:flutter/material.dart';

import 'package:bidbird/core/errors/error_mapper.dart';
import 'package:bidbird/features/bid/domain/usecases/orchestrations/place_bid_flow_usecase.dart';
import 'package:bidbird/features/bid/domain/usecases/check_bid_restriction_usecase.dart';
import 'package:bidbird/features/bid/data/repositories/bid_repository.dart';

class PriceInputViewModel extends ChangeNotifier {
  PriceInputViewModel({PlaceBidFlowUseCase? placeBidFlowUseCase})
    : _placeBidFlowUseCase =
          placeBidFlowUseCase ??
          PlaceBidFlowUseCase(
            checkBidRestrictionUseCase: CheckBidRestrictionUseCase(
              BidRepositoryImpl(),
            ),
            repository: BidRepositoryImpl(),
          );

  final PlaceBidFlowUseCase _placeBidFlowUseCase;

  bool isSubmitting = false;

  // 임시로 주석 처리: 결제 비활성화
  /*
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
      throw Exception(ErrorMapper().map(e));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
  */

  Future<void> Temporary_bid({
    required String itemId,
    required int bidPrice,
    bool isInstant = false,
  }) async {
    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final (result, error) = await _placeBidFlowUseCase.placeBid(
        itemId: itemId,
        bidPrice: bidPrice,
      );

      if (error != null) {
        throw Exception(ErrorMapper().map(error.message));
      }

      if (result == null || !result.success) {
        throw Exception('입찰 처리 중 오류가 발생했습니다.');
      }
    } catch (e) {
      throw Exception(ErrorMapper().map(e));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
