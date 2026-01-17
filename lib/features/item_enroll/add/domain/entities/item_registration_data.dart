/// 매물 등록 결과 데이터 모델
class ItemRegistrationData {
  final String id;
  final String title;
  final String description;
  final int startPrice;
  final int instantPrice;
  final int auctionDurationHours;
  final String thumbnailUrl;
  final int keywordTypeId;
  final String statusText;

  ItemRegistrationData({
    required this.id,
    required this.title,
    required this.description,
    required this.startPrice,
    required this.instantPrice,
    required this.auctionDurationHours,
    required this.thumbnailUrl,
    required this.keywordTypeId,
    required this.statusText,
  });
}
