class ItemAddData {
  ItemAddData({
    required this.title,
    required this.description,
    required this.startPrice,
    required this.instantPrice,
    required this.keywordTypeId,
    required this.auctionStartAt,
    required this.auctionEndAt,
    required this.auctionDurationHours,
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
  final int auctionDurationHours;
  final List<String> imageUrls;
  final bool isAgree;

  Map<String, dynamic> toJson({required String sellerId}) {
    return <String, dynamic>{
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'start_price': startPrice,
      'buy_now_price': instantPrice,
      'current_price': startPrice,
      'bidding_count': 0,
      'status': 'READY',
      'keyword_type': keywordTypeId,
      'auction_start_at': auctionStartAt.toIso8601String(),
      'auction_end_at': auctionEndAt.toIso8601String(),
      'auction_duration_hours': auctionDurationHours,
      'locked': false,
      'is_agree': isAgree,
    };
  }
}

//