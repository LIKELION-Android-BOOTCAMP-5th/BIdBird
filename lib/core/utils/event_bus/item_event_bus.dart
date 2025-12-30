class ItemUpdateEvent {
  final String itemId;
  final int? biddingCount;
  final int? currentPrice;
  // 필요한 경우 status 등 추가

  ItemUpdateEvent({
    required this.itemId,
    this.biddingCount,
    this.currentPrice,
  });
}
