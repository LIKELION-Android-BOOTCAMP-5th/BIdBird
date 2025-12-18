import 'package:bidbird/features/bid/domain/repositories/bid_repository.dart';

/// 현재 사용자 입찰 제한 여부를 확인하는 유즈케이스
class CheckBidRestrictionUseCase {
  CheckBidRestrictionUseCase(this._repository);

  final BidRepository _repository;

  Future<bool> call() {
    return _repository.isBidRestricted();
  }
}



