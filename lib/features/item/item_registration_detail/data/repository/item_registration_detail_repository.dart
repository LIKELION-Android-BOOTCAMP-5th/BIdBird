import '../datasource/item_registration_detail_datasource.dart';

class ItemRegistrationDetailRepository {
  ItemRegistrationDetailRepository({ItemRegistrationDetailDatasource? datasource})
      : _datasource = datasource ?? ItemRegistrationDetailDatasource();

  final ItemRegistrationDetailDatasource _datasource;

  Future<String> fetchTermsText() {
    return _datasource.fetchTermsText();
  }

  Future<DateTime> confirmRegistration(String itemId) {
    return _datasource.confirmRegistration(itemId);
  }
}

// TODO: implement ItemRegistrationDetailRepository here
