import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart';

/// 입찰 내역 조회 유즈케이스
class FetchBidHistoryUseCase {
  FetchBidHistoryUseCase(this._repository);

  final ItemDetailRepository _repository;

  Future<List<BidHistoryItem>> call(String itemId) {
    return _repository.fetchBidHistory(itemId);
  }
}

