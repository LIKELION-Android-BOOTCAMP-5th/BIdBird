enum TradeRole { seller, buyer }

class TradeHistoryEntity {
  const TradeHistoryEntity({
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

class TradeHistoryPageEntity {
  const TradeHistoryPageEntity({
    required this.items,
    required this.hasMore,
  });

  final List<TradeHistoryEntity> items;
  final bool hasMore;
}
