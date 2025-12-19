import '../../domain/entities/trade_history_entity.dart';

class TradeHistoryDto {
  TradeHistoryDto({
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

  TradeHistoryEntity toEntity() {
    return TradeHistoryEntity(
      itemId: itemId,
      title: title,
      currentPrice: currentPrice,
      statusCode: statusCode,
      role: role,
      thumbnailUrl: thumbnailUrl,
      buyNowPrice: buyNowPrice,
      createdAt: createdAt,
      endAt: endAt,
    );
  }
}
