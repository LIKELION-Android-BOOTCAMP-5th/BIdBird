class EditItemEntity {
  EditItemEntity({
    required this.title,
    required this.description,
    required this.startPrice,
    required this.buyNowPrice,
    required this.keywordTypeId,
    required this.auctionDurationHours,
    required this.imageUrls,
  });

  final String title;
  final String description;
  final int startPrice;
  final int buyNowPrice;
  final int keywordTypeId;
  final int auctionDurationHours;
  final List<String> imageUrls;
}
