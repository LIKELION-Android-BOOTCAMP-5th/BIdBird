import 'edit_item_entity.dart';
import 'edit_item_gateway.dart';

class GetEditItemUseCase {
  GetEditItemUseCase(this._gateway);

  final EditItemGateway _gateway;

  Future<EditItemEntity> call(String itemId) {
    return _gateway.fetchItemForEdit(itemId);
  }
}
