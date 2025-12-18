import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';

class ItemBidWinEntity {
  ItemBidWinEntity({
    required this.itemId,
    required this.title,
    required this.images,
    required this.winPrice,
    this.tradeStatusCode,
  });

  final String itemId;
  final String title;
  final List<String> images;
  final int winPrice;
  final int? tradeStatusCode;

  factory ItemBidWinEntity.fromItemDetail(ItemDetail item) {
    return ItemBidWinEntity(
      itemId: item.itemId,
      title: item.itemTitle,
      images: item.itemImages,
      winPrice: item.currentPrice,
      tradeStatusCode: item.tradeStatusCode,
    );
  }
}

