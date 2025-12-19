import '../entities/items_entity.dart';
import '../entities/keywordType_entity.dart';

abstract class HomeRepository {
  Future<List<KeywordType>> getKeywordType();
  Future<List<ItemsEntity>> fetchItems(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
  });
  Future<List<ItemsEntity>> fetchSearchResult(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
    String? userInputSearchText,
  });
}
