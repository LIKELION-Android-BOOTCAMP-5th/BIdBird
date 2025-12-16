import 'package:bidbird/features/item/trade_status/data/datasource/trade_status_datasource.dart';
import 'package:bidbird/features/item/trade_status/model/trade_status_entity.dart';

abstract class TradeStatusRepository {
  Future<TradeStatusEntity> fetchTradeStatus(String itemId);
}

class TradeStatusRepositoryImpl implements TradeStatusRepository {
  TradeStatusRepositoryImpl({TradeStatusDatasource? datasource})
      : _datasource = datasource ?? TradeStatusDatasource();

  final TradeStatusDatasource _datasource;

  @override
  Future<TradeStatusEntity> fetchTradeStatus(String itemId) {
    return _datasource.fetchTradeStatus(itemId);
  }
}

