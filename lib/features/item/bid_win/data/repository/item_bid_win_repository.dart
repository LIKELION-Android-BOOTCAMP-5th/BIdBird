import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';

import '../../model/item_bid_win_entity.dart';
import '../datasource/item_bid_win_datasource.dart';

class ItemBidWinRepository {
  ItemBidWinRepository({ItemBidWinDatasource? datasource})
      : _datasource = datasource ?? ItemBidWinDatasource();

  final ItemBidWinDatasource _datasource;

  ItemBidWinEntity fromItemDetail(ItemDetail item) {
    return _datasource.toEntityFromDetail(item);
  }
}
