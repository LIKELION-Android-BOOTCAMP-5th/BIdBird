import '../datasource/item_registration_data.dart';

class ItemRegistrationRepository {
  ItemRegistrationRepository({ItemRegistrationDatasource? datasource})
      : _datasource = datasource ?? ItemRegistrationDatasource();

  final ItemRegistrationDatasource _datasource;

  Future<void> registerItem(String itemId, DateTime auctionStartAt) {
    return _datasource.registerItem(itemId, auctionStartAt);
  }
}
