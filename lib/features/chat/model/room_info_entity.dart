// ==========================================================
// RoomInfoEntity 전체 모델 (item, auction, opponent, trade)
// ==========================================================

class RoomInfoEntity {
  final ItemInfoEntity item;
  final AuctionInfoEntity auction;
  final OpponentEntity opponent;
  TradeInfoEntity? trade;

  RoomInfoEntity({
    required this.item,
    required this.auction,
    required this.opponent,
    required this.trade,
  });

  factory RoomInfoEntity.fromJson(Map<String, dynamic> json) {
    return RoomInfoEntity(
      item: ItemInfoEntity.fromJson(json["item"]),
      auction: AuctionInfoEntity.fromJson(json["auction"]),
      opponent: OpponentEntity.fromJson(json["opponent"]),
      trade: json["trade"] != null
          ? TradeInfoEntity.fromJson(json["trade"])
          : null,
    );
  }
}

// ==========================================================
// ItemEntity
// ==========================================================

class ItemInfoEntity {
  final String itemId;
  final String sellerId;
  final String title;
  final String? thumbnailImage;

  ItemInfoEntity({
    required this.itemId,
    required this.sellerId,
    required this.title,
    required this.thumbnailImage,
  });

  factory ItemInfoEntity.fromJson(Map<String, dynamic> json) {
    return ItemInfoEntity(
      itemId: json['item_id'] as String,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      thumbnailImage: json['thumbnail_image'] as String?,
    );
  }
}

// ==========================================================
// AuctionEntity
// ==========================================================

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

// ==========================================================
// OpponentEntity 상대방
// ==========================================================

class OpponentEntity {
  final String? profileImage;
  final String nickName;

  OpponentEntity({required this.profileImage, required this.nickName});

  factory OpponentEntity.fromJson(Map<String, dynamic> json) {
    return OpponentEntity(
      profileImage: json['profile_image'] as String?,
      nickName: json['nick_name'] as String,
    );
  }
}

// ==========================================================
// TradeEntity (nullable 가능)
// ==========================================================

class TradeInfoEntity {
  final String tradeId;
  final String itemId;
  final String bidId;
  final String sellerId;
  final String buyerId;
  final int price;
  final int tradeStatusCode;
  final String paymentDeadline;
  final String? paidAt;
  final String? canceledAt;
  final String? shippingAddress;
  final String? shippingStartAt;
  final String? shippingCompletedAt;

  TradeInfoEntity({
    required this.tradeId,
    required this.itemId,
    required this.bidId,
    required this.sellerId,
    required this.buyerId,
    required this.price,
    required this.tradeStatusCode,
    required this.paymentDeadline,
    required this.paidAt,
    required this.canceledAt,
    required this.shippingAddress,
    required this.shippingStartAt,
    required this.shippingCompletedAt,
  });

  factory TradeInfoEntity.fromJson(Map<String, dynamic> json) {
    return TradeInfoEntity(
      tradeId: json['trade_id'] as String,
      itemId: json['item_id'] as String,
      bidId: json['bid_id'] as String,
      sellerId: json['seller_id'] as String,
      buyerId: json['buyer_id'] as String,
      price: json['price'] as int,
      tradeStatusCode: json['trade_status_code'] as int,
      paymentDeadline: json['payment_deadline'] as String,
      paidAt: json['paid_at'] as String?,
      canceledAt: json['canceled_at'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingStartAt: json['shipping_start_at'] as String?,
      shippingCompletedAt: json['shipping_completed_at'] as String?,
    );
  }
}
