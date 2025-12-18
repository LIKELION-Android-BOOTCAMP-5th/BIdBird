import '../entities/item_registration_entity.dart';

abstract class ItemRegistrationListRepository {
  Future<List<ItemRegistrationData>> fetchMyPendingItems();
}



