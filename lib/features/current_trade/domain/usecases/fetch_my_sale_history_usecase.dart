import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/domain/repositories/current_trade_repository.dart';

/// 내 판매 내역 조회 유즈케이스
class FetchMySaleHistoryUseCase {
  FetchMySaleHistoryUseCase(this._repository);

  final CurrentTradeRepository _repository;

  Future<List<SaleHistoryItem>> call({int page = 1, int limit = 20}) {
    return _repository.fetchMySaleHistory(page: page, limit: limit);
  }
}
