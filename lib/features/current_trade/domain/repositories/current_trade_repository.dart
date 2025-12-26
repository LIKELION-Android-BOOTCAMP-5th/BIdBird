import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';

/// Current Trade 도메인 리포지토리 인터페이스
abstract class CurrentTradeRepository {
  /// 입찰 내역 + 판매 내역을 한 번에 불러오기 (통합)
  Future<
    ({
      List<BidHistoryItem> bidHistory,
      List<SaleHistoryItem> saleHistory,
      Map<String, dynamic> pagination,
    })
  >
  fetchMyCurrentTrades({int page = 1, int limit = 20});

  /// 입찰 내역만 불러오기 (호환성)
  Future<List<BidHistoryItem>> fetchMyBidHistory({
    int page = 1,
    int limit = 20,
  });

  /// 판매 내역만 불러오기 (호환성)
  Future<List<SaleHistoryItem>> fetchMySaleHistory({
    int page = 1,
    int limit = 20,
  });
}
