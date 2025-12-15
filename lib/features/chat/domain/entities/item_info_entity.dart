class ItemInfoEntity {
  final String itemId;
  final String sellerId;
  final String title;
  final String? thumbnailImage;

  ItemInfoEntity({
    required this.itemId,
    required this.sellerId,
    required this.title,
    required this.thumbnailImage,
  });

  factory ItemInfoEntity.fromJson(Map<String, dynamic> json) {
    return ItemInfoEntity(
      itemId: json['item_id'] as String,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      thumbnailImage: json['thumbnail_image'] as String?,
    );
  }
}
