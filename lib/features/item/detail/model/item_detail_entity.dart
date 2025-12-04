class ItemDetail {
  ItemDetail({
    required this.itemId,
    required this.sellerId,
    required this.itemTitle,
    required this.itemImages,
    required this.finishTime,
    required this.sellerTitle,
    required this.buyNowPrice,
    required this.biddingCount,
    required this.itemContent,
    required this.currentPrice,
    required this.bidPrice,
    required this.sellerRating,
    required this.sellerReviewCount,
  });

  final String itemId;
  final String sellerId;
  final String itemTitle;
  final List<String> itemImages;
  final DateTime finishTime;
  final String sellerTitle;
  final int buyNowPrice;
  final int biddingCount;
  final String itemContent;
  final int currentPrice;
  final int bidPrice;
  final double sellerRating;
  final int sellerReviewCount;
}
