import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';

import '../datasource/item_registration_list_datasource.dart';

abstract class RegistrationRepository {
  Future<List<ItemRegistrationData>> fetchMyPendingItems();
}

class RegistrationRepositoryImpl implements RegistrationRepository {
  RegistrationRepositoryImpl({RegistrationDatasource? datasource})
      : _datasource = datasource ?? RegistrationDatasource();

  final RegistrationDatasource _datasource;

  @override
  Future<List<ItemRegistrationData>> fetchMyPendingItems() {
    return _datasource.fetchMyPendingItems();
  }
}

