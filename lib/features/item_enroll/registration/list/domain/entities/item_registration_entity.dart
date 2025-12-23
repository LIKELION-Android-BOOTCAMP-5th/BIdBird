class ItemRegistrationData {
  ItemRegistrationData({
    required this.id,
    required this.title,
    required this.description,
    required this.startPrice,
    required this.instantPrice,
    required this.auctionDurationHours,
    required this.statusText,
    this.thumbnailUrl,
    this.keywordTypeId,
  });

  final String id;
  final String title;
  final String description;
  final int startPrice;
  final int instantPrice;
  final int auctionDurationHours;
  final String statusText;
  final String? thumbnailUrl;
  final int? keywordTypeId;
}



