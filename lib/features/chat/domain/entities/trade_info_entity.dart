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



