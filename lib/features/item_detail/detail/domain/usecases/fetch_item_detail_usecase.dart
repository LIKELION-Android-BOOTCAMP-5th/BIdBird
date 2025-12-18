import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart';

/// 상품 상세 정보 조회 유즈케이스
class FetchItemDetailUseCase {
  FetchItemDetailUseCase(this._repository);

  final ItemDetailRepository _repository;

  Future<ItemDetail?> call(String itemId) {
    return _repository.fetchItemDetail(itemId);
  }
}

