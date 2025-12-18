import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart';

/// 즐겨찾기 토글 유즈케이스
class ToggleFavoriteUseCase {
  ToggleFavoriteUseCase(this._repository);

  final ItemDetailRepository _repository;

  Future<void> call(String itemId, bool currentState) {
    return _repository.toggleFavorite(itemId, currentState);
  }
}

