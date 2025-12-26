class ItemAddEntity {
  ItemAddEntity({
    required this.title,
    required this.description,
    required this.startPrice,
    required this.instantPrice,
    required this.keywordTypeId,
    required this.auctionStartAt,
    required this.auctionEndAt,
    required this.auctionDurationHours,
    required this.imageUrls,
    required this.documentUrls,
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
  final List<String> documentUrls;
  final bool isAgree;

  Map<String, dynamic> toJson({required String sellerId}) {
    // current_price, bidding_count, status는 auctions 테이블에 저장되므로 items_detail에는 포함하지 않음
    // auction_start_at, auction_end_at도 auctions 테이블에 저장됨
    return <String, dynamic>{
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'start_price': startPrice,
      'buy_now_price': instantPrice,
      'keyword_type': keywordTypeId,
      'auction_duration_hours': auctionDurationHours,
      'document_urls': documentUrls,
      'is_agree': isAgree,
    };
  }
}
