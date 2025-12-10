import 'package:bidbird/features/item/current_trade/model/current_trade_entity.dart';

import '../datasource/current_trade_data.dart';

abstract class CurrentTradeRepository {
  Future<List<BidHistoryItem>> fetchMyBidHistory();
  Future<List<SaleHistoryItem>> fetchMySaleHistory();
}

class CurrentTradeRepositoryImpl implements CurrentTradeRepository {
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
