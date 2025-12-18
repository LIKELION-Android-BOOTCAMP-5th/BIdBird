import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';

class ItemBidWinDatasource {
  ItemBidWinEntity toEntityFromDetail(ItemDetail item) {
    return ItemBidWinEntity.fromItemDetail(item);
  }
}

