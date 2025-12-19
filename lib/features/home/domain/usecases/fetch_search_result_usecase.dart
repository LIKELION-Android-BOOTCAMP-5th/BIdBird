import 'package:bidbird/features/home/domain/entities/items_entity.dart';
import 'package:bidbird/features/home/domain/repositories/home_repository.dart';

class FetchSearchResultUseCase {
  FetchSearchResultUseCase(this._repository);

  final HomeRepository _repository;

  Future<List<ItemsEntity>> call(
    String orderBy, {
    int currentIndex = 1,
    int? keywordType,
    String? userInputSearchText,
  }) {
    return _repository.fetchSearchResult(
      orderBy,
      currentIndex: currentIndex,
      keywordType: keywordType,
      userInputSearchText: userInputSearchText,
    );
  }
}
