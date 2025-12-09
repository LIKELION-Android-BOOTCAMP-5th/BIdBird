import 'edit_item_entity.dart';

abstract class EditItemGateway {
  Future<EditItemEntity> fetchItemForEdit(String itemId);
}
