class BuyNowBidRequest {
  BuyNowBidRequest({
    required this.itemId,
    required this.bidPrice,
    this.isInstant = true,
  });

  final String itemId;
  final int bidPrice;
  final bool isInstant;
}
