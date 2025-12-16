import '../datasource/item_registration_detail_datasource.dart';

abstract class ItemRegistrationDetailRepository {
  Future<String> fetchTermsText();
  Future<void> confirmRegistration(String itemId);
  Future<void> deleteItem(String itemId);
  Future<String?> fetchFirstImageUrl(String itemId);
}

class ItemRegistrationDetailRepositoryImpl implements ItemRegistrationDetailRepository {
  ItemRegistrationDetailRepositoryImpl({ItemRegistrationDetailDatasource? datasource})
      : _datasource = datasource ?? ItemRegistrationDetailDatasource();

  final ItemRegistrationDetailDatasource _datasource;

  @override
  Future<String> fetchTermsText() {
    return _datasource.fetchTermsText();
  }

  @override
  Future<void> confirmRegistration(String itemId) {
    return _datasource.confirmRegistration(itemId);
  }

  @override
  Future<void> deleteItem(String itemId) {
    return _datasource.deleteItem(itemId);
  }

  @override
  Future<String?> fetchFirstImageUrl(String itemId) {
    return _datasource.fetchFirstImageUrl(itemId);
  }
}
