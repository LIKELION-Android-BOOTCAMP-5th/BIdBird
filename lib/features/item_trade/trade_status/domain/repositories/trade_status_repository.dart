import 'package:bidbird/features/item_trade/trade_status/domain/entities/trade_status_entity.dart';

/// Trade Status 도메인 리포지토리 인터페이스
abstract class TradeStatusRepository {
  Future<TradeStatusEntity> fetchTradeStatus(String itemId);
}



