import 'package:flutter/material.dart';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/features/bid/domain/entities/bid_request_entity.dart';
import 'package:bidbird/features/bid/domain/usecases/place_bid_usecase.dart';
import 'package:bidbird/features/bid/data/repositories/bid_repository.dart';

class PriceInputViewModel extends ChangeNotifier {
  PriceInputViewModel({PlaceBidUseCase? placeBidUseCase})
      : _placeBidUseCase =
            placeBidUseCase ?? PlaceBidUseCase(BidRepositoryImpl());

  final PlaceBidUseCase _placeBidUseCase;

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
    bool isInstant = false,
  }) async {
    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception(ItemRegistrationErrorMessages.loginRequired);
      }

      final response = await supabase.rpc(
        'temporary_bid',
        params: <String, dynamic>{
          'p_item_id': itemId,
          'p_bidder_id': user.id,
          'p_bid_price': bidPrice,
        },
      );

      if (response is! Map<String, dynamic>) {
        throw Exception('입찰 처리 중 오류가 발생했습니다.');
      }

      final resultCode = response['result_code'] as String?;
      final message =
          response['message'] as String? ?? '입찰 처리 중 오류가 발생했습니다.';

      if (resultCode != 'SUCCESS') {
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}



