import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';

/// 입찰/판매 내역을 통합 리스트로 변환
List<({bool isSeller, bool isHighlighted, dynamic item})> mergeTradeHistory({
  required List<SaleHistoryItem> saleHistory,
  required List<BidHistoryItem> bidHistory,
}) {
  final List<({bool isSeller, bool isHighlighted, dynamic item})> all = [];
  all.addAll(saleHistory.map((e) => (isSeller: true, isHighlighted: false, item: e)));
  all.addAll(bidHistory.map((e) => (isSeller: false, isHighlighted: false, item: e)));
  // 최신순 정렬 가정: createdAt 필드가 있다면 활용하도록 확장 가능
  return all;
}
