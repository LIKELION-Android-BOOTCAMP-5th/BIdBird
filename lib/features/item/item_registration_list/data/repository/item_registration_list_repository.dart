import 'package:bidbird/features/item/item_registration_list/model/item_registration_entity.dart';

import '../datasource/item_registration_list_datasource.dart';

class RegistrationRepository {
  RegistrationRepository({RegistrationDatasource? datasource})
      : _datasource = datasource ?? RegistrationDatasource();

  final RegistrationDatasource _datasource;

  Future<List<ItemRegistrationData>> fetchMyPendingItems() {
    return _datasource.fetchMyPendingItems();
  }
}

