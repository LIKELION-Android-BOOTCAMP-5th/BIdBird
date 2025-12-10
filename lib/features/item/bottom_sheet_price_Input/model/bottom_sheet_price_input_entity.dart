class BidRequest {
  BidRequest({
    required this.itemId,
    required this.bidPrice,
    this.isInstant = false,
  });

  final String itemId;
  final int bidPrice;
  final bool isInstant;
}
