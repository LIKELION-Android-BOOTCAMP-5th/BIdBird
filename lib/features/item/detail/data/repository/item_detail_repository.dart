import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';

import '../datasource/item_detail_datasource.dart';

class ItemDetailRepository {
  ItemDetailRepository({ItemDetailDatasource? datasource})
      : _datasource = datasource ?? ItemDetailDatasource();

  final ItemDetailDatasource _datasource;

  Future<ItemDetail?> fetchItemDetail(String itemId) {
    return _datasource.fetchItemDetail(itemId);
  }

  Future<bool> checkIsFavorite(String itemId) {
    return _datasource.checkIsFavorite(itemId);
  }

  Future<void> toggleFavorite(String itemId, bool currentState) {
    return _datasource.toggleFavorite(itemId, currentState);
  }

  Future<bool> checkIsTopBidder(String itemId) {
    return _datasource.checkIsTopBidder(itemId);
  }

  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId) {
    return _datasource.fetchSellerProfile(sellerId);
  }

  Future<List<Map<String, dynamic>>> fetchBidHistory(String itemId) {
    return _datasource.fetchBidHistory(itemId);
  }
}
