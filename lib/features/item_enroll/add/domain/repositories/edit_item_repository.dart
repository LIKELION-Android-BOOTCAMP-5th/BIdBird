import 'package:bidbird/features/item_enroll/add/domain/entities/edit_item_entity.dart';

/// Edit Item 도메인 리포지토리 인터페이스
abstract class EditItemRepository {
  Future<EditItemEntity> fetchItemForEdit(String itemId);
}



