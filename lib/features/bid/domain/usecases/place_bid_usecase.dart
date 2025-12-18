import 'package:bidbird/features/bid/domain/entities/bid_request_entity.dart';
import 'package:bidbird/features/bid/domain/repositories/bid_repository.dart';

/// 일반 입찰 실행 유즈케이스
class PlaceBidUseCase {
  PlaceBidUseCase(this._repository);

  final BidRepository _repository;

  Future<void> call(BidRequest request) {
    return _repository.placeBid(request);
  }
}



