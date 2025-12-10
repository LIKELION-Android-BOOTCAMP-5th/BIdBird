import 'package:bidbird/core/models/items_entity.dart';

import '../../model/home_data.dart';
import '../data_sources/home_network_api_datasource.dart';

class HomeRepository {
  // 반환 형태가 무엇이 되어야 할까요?
  // List<Task>
  Future<List<HomeCodeKeywordType>> getKeywordType() async {
    return await HomeNetworkApiManager.shared.getKeywordType();
  }

  Future<List<ItemsEntity>> fetchItems(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
  }) async {
    return await HomeNetworkApiManager.shared.getItems(
      orderBy,
      currentIndex: currentIndex,
      keywordType: keywordType,
    );
  }

  Future<List<ItemsEntity>> fetchSearchResult(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
    String? userInputSearchText,
  }) async {
    return await HomeNetworkApiManager.shared.getSearchResults(
      orderBy,
      currentIndex: currentIndex,
      keywordType: keywordType,
      userInputSearchText: userInputSearchText,
    );
  }
}
