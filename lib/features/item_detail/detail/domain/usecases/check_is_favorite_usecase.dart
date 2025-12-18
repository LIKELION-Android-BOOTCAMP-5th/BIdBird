import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart';

/// 즐겨찾기 여부 확인 유즈케이스
class CheckIsFavoriteUseCase {
  CheckIsFavoriteUseCase(this._repository);

  final ItemDetailRepository _repository;

  Future<bool> call(String itemId) {
    return _repository.checkIsFavorite(itemId);
  }
}

