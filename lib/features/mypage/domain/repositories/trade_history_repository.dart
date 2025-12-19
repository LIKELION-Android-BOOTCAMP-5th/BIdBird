import '../entities/trade_history_entity.dart';

abstract class TradeHistoryRepository {
  Future<TradeHistoryPageEntity> fetchHistory({
    required TradeRole role,
    int? statusCode,
    required int page,
    required int pageSize,
  });
}
