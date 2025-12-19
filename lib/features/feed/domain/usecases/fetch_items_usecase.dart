import '../entities/items_entity.dart';
import '../repositories/home_repository.dart';

class FetchItemsUseCase {
  FetchItemsUseCase(this._repository);

  final HomeRepository _repository;

  Future<List<ItemsEntity>> call(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
  }) {
    return _repository.fetchItems(
      orderBy,
      currentIndex: currentIndex,
      keywordType: keywordType,
    );
  }
}
