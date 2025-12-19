class FavoriteEntity {
  const FavoriteEntity({
    required this.favoriteId,
    required this.itemId,
    required this.title,
    required this.thumbnailUrl,
    required this.currentPrice,
    required this.buyNowPrice,
    required this.statusCode,
    required this.isFavorite,
  });

  final String favoriteId;
  final String itemId;
  final String title;
  final String? thumbnailUrl;
  final int currentPrice;
  final int? buyNowPrice;
  final int statusCode;
  final bool isFavorite;

  FavoriteEntity copyWith({bool? isFavorite}) {
    return FavoriteEntity(
      favoriteId: favoriteId,
      itemId: itemId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      currentPrice: currentPrice,
      buyNowPrice: buyNowPrice,
      statusCode: statusCode,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
