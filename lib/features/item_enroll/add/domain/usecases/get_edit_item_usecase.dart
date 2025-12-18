import 'package:bidbird/features/item_enroll/add/domain/entities/edit_item_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/repositories/edit_item_repository.dart';

class GetEditItemUseCase {
  GetEditItemUseCase(this._repository);

  final EditItemRepository _repository;

  Future<EditItemEntity> call(String itemId) {
    return _repository.fetchItemForEdit(itemId);
  }
}
