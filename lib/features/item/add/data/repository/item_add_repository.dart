import 'package:bidbird/features/item/add/model/item_add_entity.dart';
import 'package:bidbird/features/item/add/gateway/item_add_gateway.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';

import '../datasource/supabase_item_add_datasource.dart';

class ItemAddGatewayImpl implements ItemAddGateway {
  ItemAddGatewayImpl({SupabaseItemAddDatasource? datasource})
      : _datasource = datasource ?? SupabaseItemAddDatasource();

  final SupabaseItemAddDatasource _datasource;

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
