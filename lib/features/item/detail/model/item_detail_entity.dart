import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';

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

  /// 부분 업데이트를 위한 copyWith 메서드
  ItemDetail copyWith({
    String? itemId,
    String? sellerId,
    String? itemTitle,
    List<String>? itemImages,
    DateTime? finishTime,
    String? sellerTitle,
    int? buyNowPrice,
    int? biddingCount,
    String? itemContent,
    int? currentPrice,
    int? bidPrice,
    double? sellerRating,
    int? sellerReviewCount,
    int? statusCode,
    int? tradeStatusCode,
  }) {
    return ItemDetail(
      itemId: itemId ?? this.itemId,
      sellerId: sellerId ?? this.sellerId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemImages: itemImages ?? this.itemImages,
      finishTime: finishTime ?? this.finishTime,
      sellerTitle: sellerTitle ?? this.sellerTitle,
      buyNowPrice: buyNowPrice ?? this.buyNowPrice,
      biddingCount: biddingCount ?? this.biddingCount,
      itemContent: itemContent ?? this.itemContent,
      currentPrice: currentPrice ?? this.currentPrice,
      bidPrice: bidPrice ?? this.bidPrice,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerReviewCount: sellerReviewCount ?? this.sellerReviewCount,
      statusCode: statusCode ?? this.statusCode,
      tradeStatusCode: tradeStatusCode ?? this.tradeStatusCode,
    );
  }
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
      if (trade is! Map<String, dynamic>) continue;
      final rating = getDoubleFromRow(trade, 'rating');
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

