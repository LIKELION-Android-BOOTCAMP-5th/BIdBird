import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart';

/// 판매자 프로필 조회 유즈케이스
class FetchSellerProfileUseCase {
  FetchSellerProfileUseCase(this._repository);

  final ItemDetailRepository _repository;

  Future<Map<String, dynamic>?> call(String sellerId) {
    return _repository.fetchSellerProfile(sellerId);
  }
}

