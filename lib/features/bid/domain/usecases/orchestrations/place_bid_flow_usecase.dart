import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/features/bid/domain/usecases/check_bid_restriction_usecase.dart';
import 'package:bidbird/features/bid/data/repositories/bid_repository.dart';

class PlaceBidFlowResult {
  final bool success;
  final String? message;
  const PlaceBidFlowResult({required this.success, this.message});
}

class PlaceBidFlowError {
  final String message;
  const PlaceBidFlowError(this.message);
}

class PlaceBidFlowUseCase {
  PlaceBidFlowUseCase({
    required CheckBidRestrictionUseCase checkBidRestrictionUseCase,
    BidRepositoryImpl? repository,
  }) : _checkBidRestrictionUseCase = checkBidRestrictionUseCase;

  final CheckBidRestrictionUseCase _checkBidRestrictionUseCase;
  Future<(PlaceBidFlowResult?, PlaceBidFlowError?)> placeBid({
    required String itemId,
    required int bidPrice,
  }) async {
    try {
      // 1. 입찰 제한 확인
      final isRestricted = await _checkBidRestrictionUseCase();
      if (isRestricted) {
        return (null, const PlaceBidFlowError('입찰이 제한되었습니다.'));
      }

      // 2. 사용자 확인
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      if (user == null) {
        return (
          null,
          PlaceBidFlowError(ItemRegistrationErrorMessages.loginRequired),
        );
      }

      // 3. RPC 호출 (temporary_bid)
      final response = await supabase.rpc(
        'temporary_bid',
        params: <String, dynamic>{
          'p_item_id': itemId,
          'p_bidder_id': user.id,
          'p_bid_price': bidPrice,
        },
      );

      if (response is! Map<String, dynamic>) {
        return (null, const PlaceBidFlowError('입찰 처리 중 오류가 발생했습니다.'));
      }

      final resultCode = getNullableStringFromRow(response, 'result_code');
      final message =
          getNullableStringFromRow(response, 'message') ??
          '입찰 처리 중 오류가 발생했습니다.';

      if (resultCode != 'SUCCESS') {
        return (null, PlaceBidFlowError(message));
      }

      // 4. 성공
      return (PlaceBidFlowResult(success: true, message: message), null);
    } catch (e) {
      return (null, PlaceBidFlowError(e.toString()));
    }
  }
}
