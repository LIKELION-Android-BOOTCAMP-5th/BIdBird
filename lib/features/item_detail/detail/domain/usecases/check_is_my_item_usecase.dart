import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart';

/// 내 상품 여부 확인 유즈케이스
class CheckIsMyItemUseCase {
  CheckIsMyItemUseCase(this._repository);

  final ItemDetailRepository _repository;

  Future<bool> call(String itemId, String sellerId) {
    return _repository.checkIsMyItem(itemId, sellerId);
  }
}

