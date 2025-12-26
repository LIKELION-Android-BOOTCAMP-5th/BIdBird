import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart' show ItemDetail;

class ItemBidWinEntity {
  ItemBidWinEntity({
    required this.itemId,
    required this.title,
    required this.images,
    required this.winPrice,
    this.tradeStatusCode,
    required this.sellerId,
    required this.buyerId,
  });

  final String itemId;
  final String title;
  final List<String> images;
  final int winPrice;
  final int? tradeStatusCode;
  final String sellerId;
  final String buyerId;

  factory ItemBidWinEntity.fromItemDetail(ItemDetail item) {
    final buyerId = SupabaseManager.shared.supabase.auth.currentUser?.id ?? '';
    return ItemBidWinEntity(
      itemId: item.itemId,
      title: item.itemTitle,
      images: item.itemImages,
      winPrice: item.currentPrice,
      tradeStatusCode: item.tradeStatusCode,
      sellerId: item.sellerId,
      buyerId: buyerId,
    );
  }
}

