import 'package:bidbird/features/current_trade/data/datasources/current_trade_datasource.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/domain/repositories/current_trade_repository.dart'
    as domain;

/// Current Trade 리포지토리 구현체
class CurrentTradeRepositoryImpl implements domain.CurrentTradeRepository {
  CurrentTradeRepositoryImpl({CurrentTradeDatasource? datasource})
    : _datasource = datasource ?? CurrentTradeDatasource();

  final CurrentTradeDatasource _datasource;

  @override
  Future<
    ({
      List<BidHistoryItem> bidHistory,
      List<SaleHistoryItem> saleHistory,
      Map<String, dynamic> pagination,
    })
  >
  fetchMyCurrentTrades({int page = 1, int limit = 20}) {
    return _datasource.fetchMyCurrentTrades(page: page, limit: limit);
  }

  @override
  Future<List<BidHistoryItem>> fetchMyBidHistory({
    int page = 1,
    int limit = 20,
  }) {
    return _datasource.fetchMyBidHistory(page: page, limit: limit);
  }

  @override
  Future<List<SaleHistoryItem>> fetchMySaleHistory({
    int page = 1,
    int limit = 20,
  }) {
    return _datasource.fetchMySaleHistory(page: page, limit: limit);
  }
}
