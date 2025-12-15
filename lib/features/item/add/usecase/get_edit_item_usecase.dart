import 'package:bidbird/features/item/add/model/edit_item_entity.dart';
import 'package:bidbird/features/item/add/gateway/edit_item_gateway.dart';

class GetEditItemUseCase {
  GetEditItemUseCase(this._gateway);

  final EditItemGateway _gateway;

  Future<EditItemEntity> call(String itemId) {
    return _gateway.fetchItemForEdit(itemId);
  }
}
