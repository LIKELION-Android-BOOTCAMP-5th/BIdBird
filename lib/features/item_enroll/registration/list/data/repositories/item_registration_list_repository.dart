import '../../domain/repositories/item_registration_list_repository.dart';
import '../../domain/entities/item_registration_entity.dart';
import '../datasources/item_registration_list_datasource.dart';

class ItemRegistrationListRepositoryImpl implements ItemRegistrationListRepository {
  ItemRegistrationListRepositoryImpl({ItemRegistrationListDatasource? datasource})
      : _datasource = datasource ?? ItemRegistrationListDatasource();

  final ItemRegistrationListDatasource _datasource;

  @override
  Future<List<ItemRegistrationData>> fetchMyPendingItems() {
    return _datasource.fetchMyPendingItems();
  }
}



