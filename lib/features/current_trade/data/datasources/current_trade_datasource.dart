import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrentTradeDatasource {
  CurrentTradeDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  /// 입찰 내역 + 판매 내역을 한 번에 불러오기 (직접 RPC 호출)
  Future<
    ({
      List<BidHistoryItem> bidHistory,
      List<SaleHistoryItem> saleHistory,
      Map<String, dynamic> pagination,
    })
  >
  fetchMyCurrentTrades({int page = 1, int limit = 20}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return (
        bidHistory: <BidHistoryItem>[],
        saleHistory: <SaleHistoryItem>[],
        pagination: <String, dynamic>{},
      );
    }

    try {
      // 직접 RPC 호출 (엣지 함수 제거)
      final result = await _supabase.rpc(
        'get_my_current_trades',
        params: {'p_page': page, 'p_limit': limit},
      );

      if (result == null) {
        return (
          bidHistory: <BidHistoryItem>[],
          saleHistory: <SaleHistoryItem>[],
          pagination: <String, dynamic>{},
        );
      }

      final resultData = result as Map<String, dynamic>;

      if (resultData['error'] != null) {
        return (
          bidHistory: <BidHistoryItem>[],
          saleHistory: <SaleHistoryItem>[],
          pagination: <String, dynamic>{},
        );
      }

      final bidHistoryList = (resultData['bidHistory'] as List<dynamic>?) ?? [];
      final saleHistoryList =
          (resultData['saleHistory'] as List<dynamic>?) ?? [];
      final pagination =
          (resultData['pagination'] as Map<String, dynamic>?) ??
          <String, dynamic>{};

      // 입찰 내역 파싱
      final List<BidHistoryItem> bidHistory = bidHistoryList.map((item) {
        final map = item as Map<String, dynamic>;
        return BidHistoryItem(
          itemId: map['itemId']?.toString() ?? '',
          title: map['title']?.toString() ?? '',
          price: (map['price'] as num?)?.toInt() ?? 0,
          thumbnailUrl: map['thumbnailUrl']?.toString(),
          status: map['status']?.toString() ?? '',
          tradeStatusCode: map['tradeStatusCode'] as int?,
          auctionStatusCode: map['auctionStatusCode'] as int?,
          hasShippingInfo: map['hasShippingInfo'] as bool? ?? false,
        );
      }).toList();

      // 판매 내역 파싱
      final List<SaleHistoryItem> saleHistory = saleHistoryList.map((item) {
        final map = item as Map<String, dynamic>;
        return SaleHistoryItem(
          itemId: map['itemId']?.toString() ?? '',
          title: map['title']?.toString() ?? '',
          price: (map['price'] as num?)?.toInt() ?? 0,
          thumbnailUrl: map['thumbnailUrl']?.toString(),
          status: map['status']?.toString() ?? '',
          date: map['date']?.toString() ?? '',
          tradeStatusCode: map['tradeStatusCode'] as int?,
          auctionStatusCode: map['auctionStatusCode'] as int?,
          hasShippingInfo: map['hasShippingInfo'] as bool? ?? false,
        );
      }).toList();

      return (
        bidHistory: bidHistory,
        saleHistory: saleHistory,
        pagination: pagination,
      );
    } catch (e) {
      return (
        bidHistory: <BidHistoryItem>[],
        saleHistory: <SaleHistoryItem>[],
        pagination: <String, dynamic>{},
      );
    }
  }

  /// 이전 메서드들 (호환성 유지)
  Future<List<BidHistoryItem>> fetchMyBidHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await fetchMyCurrentTrades(page: page, limit: limit);
    return result.bidHistory;
  }

  Future<List<SaleHistoryItem>> fetchMySaleHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await fetchMyCurrentTrades(page: page, limit: limit);
    return result.saleHistory;
  }
}
