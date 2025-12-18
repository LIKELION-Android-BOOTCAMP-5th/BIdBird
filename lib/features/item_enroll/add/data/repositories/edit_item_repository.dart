import 'package:bidbird/features/item_enroll/add/data/datasources/edit_item_datasource.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/edit_item_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/repositories/edit_item_repository.dart' as domain;

/// Edit Item 리포지토리 구현체
class EditItemRepositoryImpl implements domain.EditItemRepository {
  EditItemRepositoryImpl({EditItemDatasource? datasource})
      : _datasource = datasource ?? EditItemDatasource();

  final EditItemDatasource _datasource;

  @override
  Future<EditItemEntity> fetchItemForEdit(String itemId) {
    return _datasource.fetchItemForEdit(itemId);
  }
}
