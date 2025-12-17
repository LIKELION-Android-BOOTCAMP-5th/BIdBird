import 'package:bidbird/features/item/add/model/item_add_entity.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';

/// 도메인 레이어용 게이트웨이 인터페이스
abstract class ItemAddGateway {
  Future<ItemRegistrationData> saveItem({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    String? editingItemId,
    String? thumbnailUrl,
  });
}
