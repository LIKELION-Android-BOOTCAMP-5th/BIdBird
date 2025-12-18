import '../../domain/repositories/item_registration_detail_repository.dart';
import '../datasources/item_registration_detail_datasource.dart';

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

  @override
  Future<List<String>> fetchAllImageUrls(String itemId) {
    return _datasource.fetchAllImageUrls(itemId);
  }
}



