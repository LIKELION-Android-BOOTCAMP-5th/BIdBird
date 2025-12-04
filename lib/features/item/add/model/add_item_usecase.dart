import 'package:bidbird/features/item/add/model/item_add_entity.dart';
import 'package:bidbird/features/item/registration/model/item_registration_entity.dart';
import 'package:bidbird/features/item/add/data/repository/item_add_repository_impl.dart';

class AddItemUseCase {
  AddItemUseCase(this._repository);

  final ItemAddRepositoryImpl _repository;

  Future<ItemRegistrationData> call({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    String? editingItemId,
  }) {
    return _repository.saveItem(
      entity: entity,
      imageUrls: imageUrls,
      primaryImageIndex: primaryImageIndex,
      editingItemId: editingItemId,
    );
  }
}
