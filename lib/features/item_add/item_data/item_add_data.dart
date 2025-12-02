class ItemAddData {
  ItemAddData({
    required this.title,
    required this.description,
    required this.startPrice,
    required this.instantPrice,
    required this.keywordTypeId,
    required this.auctionStartAt,
    required this.auctionEndAt,
    required this.imageUrls,
    required this.isAgree,
  });

  final String title;
  final String description;
  final int startPrice;
  final int instantPrice;
  final int keywordTypeId;
  final DateTime auctionStartAt;
  final DateTime auctionEndAt;
  final List<String> imageUrls;
  final bool isAgree;

  Map<String, dynamic> toJson({required String sellerId}) {
    return <String, dynamic>{
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'thumbnail_image': imageUrls.isNotEmpty ? imageUrls.first : null,
      'start_price': startPrice,
      'buy_now_price': instantPrice,
      'current_price': startPrice,
      'bidding_count': 0,
      'status': 'READY',
      'keyword_type': keywordTypeId,
      'auction_start_at': auctionStartAt.toIso8601String(),
      'auction_end_at': auctionEndAt.toIso8601String(),
      'locked': false,
      'is_agree': isAgree,
      'image1': imageUrls.length > 0 ? imageUrls[0] : null,
      'image2': imageUrls.length > 1 ? imageUrls[1] : null,
      'image3': imageUrls.length > 2 ? imageUrls[2] : null,
      'image4': imageUrls.length > 3 ? imageUrls[3] : null,
      'image5': imageUrls.length > 4 ? imageUrls[4] : null,
      'image6': imageUrls.length > 5 ? imageUrls[5] : null,
      'image7': imageUrls.length > 6 ? imageUrls[6] : null,
      'image8': imageUrls.length > 7 ? imageUrls[7] : null,
      'image9': imageUrls.length > 8 ? imageUrls[8] : null,
      'image10': imageUrls.length > 9 ? imageUrls[9] : null,
    };
  }
}

