import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';

import '../../model/item_bid_win_entity.dart';

class ItemBidWinDatasource {
  ItemBidWinEntity toEntityFromDetail(ItemDetail item) {
    return ItemBidWinEntity.fromItemDetail(item);
  }
}
