class EditItemEntity {
  EditItemEntity({
    required this.title,
    required this.description,
    required this.startPrice,
    required this.keywordTypeId,
    required this.auctionDurationHours,
    required this.imageUrls,
    required this.documentUrls,
    this.documentNames,
    this.documentSizes,
  });

  final String title;
  final String description;
  final int startPrice;
  final int keywordTypeId;
  final int auctionDurationHours;
  final List<String> imageUrls;
  final List<String> documentUrls;
  final List<String>? documentNames;
  final List<int>? documentSizes;
}
