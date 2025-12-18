import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/domain/repositories/current_trade_repository.dart';

/// 내 입찰 내역 조회 유즈케이스
class FetchMyBidHistoryUseCase {
  FetchMyBidHistoryUseCase(this._repository);

  final CurrentTradeRepository _repository;

  Future<List<BidHistoryItem>> call() {
    return _repository.fetchMyBidHistory();
  }
}

