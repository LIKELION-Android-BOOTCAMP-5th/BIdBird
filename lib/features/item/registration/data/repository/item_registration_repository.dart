import 'package:bidbird/features/item/registration/model/item_registration_entity.dart';

import '../datasource/item_registration_data.dart';

class ItemRegistrationRepository {
  ItemRegistrationRepository({ItemRegistrationDatasource? datasource})
      : _datasource = datasource ?? ItemRegistrationDatasource();

  final ItemRegistrationDatasource _datasource;

  Future<List<ItemRegistrationData>> fetchMyPendingItems() {
    return _datasource.fetchMyPendingItems();
  }

  Future<void> registerItem(String itemId, DateTime auctionStartAt) {
    return _datasource.registerItem(itemId, auctionStartAt);
  }
}
