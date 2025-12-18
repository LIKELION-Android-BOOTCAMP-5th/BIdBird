import 'package:bidbird/features/item_trade/trade_status/data/datasources/trade_status_datasource.dart';
import 'package:bidbird/features/item_trade/trade_status/domain/entities/trade_status_entity.dart';
import 'package:bidbird/features/item_trade/trade_status/domain/repositories/trade_status_repository.dart' as domain;

/// Trade Status 리포지토리 구현체
class TradeStatusRepositoryImpl implements domain.TradeStatusRepository {
  TradeStatusRepositoryImpl({TradeStatusDatasource? datasource})
      : _datasource = datasource ?? TradeStatusDatasource();

  final TradeStatusDatasource _datasource;

  @override
  Future<TradeStatusEntity> fetchTradeStatus(String itemId) {
    return _datasource.fetchTradeStatus(itemId);
  }
}



