enum TradeRole { seller, buyer }

class TradeHistoryItem {
  TradeHistoryItem({
    required this.itemId,
    required this.title,
    required this.currentPrice,
    required this.statusCode,
    required this.role,
    this.thumbnailUrl,
    this.buyNowPrice,
    this.createdAt,
    this.endAt,
  });

  final String itemId;
  final String title;
  final int currentPrice;
  final int statusCode;
  final TradeRole role;
  final String? thumbnailUrl;
  final int? buyNowPrice;
  final DateTime? createdAt;
  final DateTime? endAt;
}
