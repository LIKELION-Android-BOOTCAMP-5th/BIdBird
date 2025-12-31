import '../entities/trade_history_entity.dart';

abstract class TradeHistoryRepository {
  Future<TradeHistoryPageEntity> fetchHistory({
    required TradeRole role,
    List<int>? statusCodes,
    required int page,
    required int pageSize,
  });
}
