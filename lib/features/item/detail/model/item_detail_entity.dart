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
    required this.statusCode,
    this.tradeStatusCode,
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
  final int statusCode;
  final int? tradeStatusCode;
}

class SellerRatingSummary {
  SellerRatingSummary({
    required this.rating,
    required this.reviewCount,
  });

  final double rating;
  final int reviewCount;

  factory SellerRatingSummary.fromCompletedTrades(
    List<dynamic> completedTrades,
  ) {
    if (completedTrades.isEmpty) {
      return SellerRatingSummary(rating: 0.0, reviewCount: 0);
    }

    double totalRating = 0;
    for (final trade in completedTrades) {
      final rating = (trade['rating'] as num?)?.toDouble() ?? 0.0;
      totalRating += rating;
    }

    final int reviewCount = completedTrades.length;
    final double averageRating =
        reviewCount > 0 ? totalRating / reviewCount : 0.0;

    return SellerRatingSummary(
      rating: averageRating,
      reviewCount: reviewCount,
    );
  }
}

