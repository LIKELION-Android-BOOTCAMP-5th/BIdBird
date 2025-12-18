import 'package:bidbird/features/item_enroll/add/data/datasources/item_add_datasource.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/repositories/item_add_repository.dart' as domain;
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';

/// Item Add 리포지토리 구현체
class ItemAddRepositoryImpl implements domain.ItemAddRepository {
  ItemAddRepositoryImpl({ItemAddDatasource? datasource})
      : _datasource = datasource ?? ItemAddDatasource();

  final ItemAddDatasource _datasource;

  @override
  Future<ItemRegistrationData> saveItem({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    String? editingItemId,
    String? thumbnailUrl,
  }) {
    return _datasource.saveItem(
      entity: entity,
      imageUrls: imageUrls,
      primaryImageIndex: primaryImageIndex,
      editingItemId: editingItemId,
      thumbnailUrl: thumbnailUrl,
    );
  }
}
