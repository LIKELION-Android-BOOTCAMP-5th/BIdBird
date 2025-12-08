import 'package:bidbird/core/models/items_entity.dart';

import '../../../core/managers/network_api_manager.dart';
import '../model/home_data.dart';

class HomeRepository {
  // 반환 형태가 무엇이 되어야 할까요?
  // List<Task>
  Future<List<HomeCodeKeywordType>> getKeywordType() async {
    return await NetworkApiManager.shared.getKeywordType();
  }

  Future<List<ItemsEntity>> fetchItems(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
  }) async {
    return await NetworkApiManager.shared.getItems(
      orderBy,
      currentIndex: currentIndex,
      keywordType: keywordType,
    );
  }
}
