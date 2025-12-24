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

/// 입찰 기록 엔티티
class BidHistoryItem {
  BidHistoryItem({
    required this.price,
    required this.userName,
    required this.userId,
    required this.createdAt,
    this.profileImageUrl,
    this.auctionLogCode,
  });

  final int price;
  final String userName;
  final String userId;
  final String createdAt;
  final String? profileImageUrl;
  final int? auctionLogCode;

  /// Map에서 BidHistoryItem 생성
  factory BidHistoryItem.fromMap(Map<String, dynamic> map) {
    final dynamic rawPrice = map['price'];
    int price = 0;
    if (rawPrice is num) {
      price = rawPrice.toInt();
    } else if (rawPrice != null) {
      price = int.tryParse(rawPrice.toString()) ?? 0;
    }

    return BidHistoryItem(
      price: price,
      userName: map['user_name']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      profileImageUrl: map['profile_image_url']?.toString(),
      auctionLogCode: map['auction_log_code'] as int?,
    );
  }

  /// Map 리스트에서 BidHistoryItem 리스트 생성
  static List<BidHistoryItem> fromMapList(List<dynamic> list) {
    return list
        .where((item) => item is Map<String, dynamic>)
        .map((item) => BidHistoryItem.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'user_name': userName,
      'user_id': userId,
      'created_at': createdAt,
      'profile_image_url': profileImageUrl,
      'auction_log_code': auctionLogCode,
    };
  }
}

