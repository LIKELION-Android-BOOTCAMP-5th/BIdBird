import 'package:bidbird/features/item/add/model/item_add_entity.dart';
import 'package:bidbird/features/item/add/gateway/item_add_gateway.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';

class AddItemUseCase {
  AddItemUseCase(this._gateway);

  final ItemAddGateway _gateway;

  Future<ItemRegistrationData> call({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    String? editingItemId,
    String? thumbnailUrl,
  }) {
    return _gateway.saveItem(
      entity: entity,
      imageUrls: imageUrls,
      primaryImageIndex: primaryImageIndex,
      editingItemId: editingItemId,
      thumbnailUrl: thumbnailUrl,
    );
  }
}
