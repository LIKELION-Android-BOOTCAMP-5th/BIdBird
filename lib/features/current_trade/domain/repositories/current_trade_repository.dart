import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';

/// Current Trade 도메인 리포지토리 인터페이스
abstract class CurrentTradeRepository {
  Future<List<BidHistoryItem>> fetchMyBidHistory();
  Future<List<SaleHistoryItem>> fetchMySaleHistory();
}



