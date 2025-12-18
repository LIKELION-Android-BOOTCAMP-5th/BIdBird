import 'package:bidbird/features/current_trade/data/datasources/current_trade_datasource.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/domain/repositories/current_trade_repository.dart' as domain;

/// Current Trade 리포지토리 구현체
class CurrentTradeRepositoryImpl implements domain.CurrentTradeRepository {
  CurrentTradeRepositoryImpl({CurrentTradeDatasource? datasource})
      : _datasource = datasource ?? CurrentTradeDatasource();

  final CurrentTradeDatasource _datasource;

  @override
  Future<List<BidHistoryItem>> fetchMyBidHistory() {
    return _datasource.fetchMyBidHistory();
  }

  @override
  Future<List<SaleHistoryItem>> fetchMySaleHistory() {
    return _datasource.fetchMySaleHistory();
  }
}



