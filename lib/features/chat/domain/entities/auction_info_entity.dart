class AuctionInfoEntity {
  final String auctionId;
  final String itemId;
  final int round;
  final String auctionStartAt;
  final String auctionEndAt;
  final int currentPrice;
  final int bidCount;
  final String? lastBidUserId;
  final String? lastBidAt;
  final int? buyNowPrice;
  final String? buyNowLock;
  final int itemStatusCode;
  final int auctionStatusCode;
  final int? tradeStatusCode;

  AuctionInfoEntity({
    required this.auctionId,
    required this.itemId,
    required this.round,
    required this.auctionStartAt,
    required this.auctionEndAt,
    required this.currentPrice,
    required this.bidCount,
    required this.lastBidUserId,
    required this.lastBidAt,
    required this.buyNowPrice,
    required this.buyNowLock,
    required this.itemStatusCode,
    required this.auctionStatusCode,
    required this.tradeStatusCode,
  });

  factory AuctionInfoEntity.fromJson(Map<String, dynamic> json) {
    return AuctionInfoEntity(
      auctionId: json['auction_id'] as String,
      itemId: json['item_id'] as String,
      round: json['round'] as int,
      auctionStartAt: json['auction_start_at'] as String,
      auctionEndAt: json['auction_end_at'] as String,
      currentPrice: json['current_price'] as int,
      bidCount: json['bid_count'] as int,
      lastBidUserId: json['last_bid_user_id'] as String?,
      lastBidAt: json['last_bid_at'] as String?,
      buyNowPrice: json['buy_now_price'] as int?,
      buyNowLock: json['buy_now_lock'] as String?,
      itemStatusCode: json['item_status_code'] as int,
      auctionStatusCode: json['auction_status_code'] as int,
      tradeStatusCode: json['trade_status_code'] as int?,
    );
  }
}