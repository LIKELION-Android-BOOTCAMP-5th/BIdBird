import 'package:bidbird/features/item/add/model/edit_item_entity.dart';

abstract class EditItemGateway {
  Future<EditItemEntity> fetchItemForEdit(String itemId);
}
