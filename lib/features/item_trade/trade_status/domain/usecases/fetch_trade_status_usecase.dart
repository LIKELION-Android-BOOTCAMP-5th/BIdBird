import 'package:bidbird/features/item_trade/trade_status/domain/entities/trade_status_entity.dart';
import 'package:bidbird/features/item_trade/trade_status/domain/repositories/trade_status_repository.dart';

/// 거래 현황 조회 유즈케이스
class FetchTradeStatusUseCase {
  FetchTradeStatusUseCase(this._repository);

  final TradeStatusRepository _repository;

  Future<TradeStatusEntity> call(String itemId) {
    return _repository.fetchTradeStatus(itemId);
  }
}

