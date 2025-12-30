import '../entities/trade_history_entity.dart';
import '../repositories/trade_history_repository.dart';

class GetTradeHistory {
  GetTradeHistory(this._repository);

  final TradeHistoryRepository _repository;

  Future<TradeHistoryPageEntity> call({
    required TradeRole role,
    List<int>? statusCodes,
    required int page,
    required int pageSize,
  }) {
    return _repository.fetchHistory(
      role: role,
      statusCodes: statusCodes,
      page: page,
      pageSize: pageSize,
    );
  }
}
