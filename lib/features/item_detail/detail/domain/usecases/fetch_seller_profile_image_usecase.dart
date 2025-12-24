import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart';

/// 판매자 프로필 이미지만 가져오는 UseCase (경량화)
class FetchSellerProfileImageUseCase {
  final ItemDetailRepository _repository;

  FetchSellerProfileImageUseCase(this._repository);

  Future<String?> call(String sellerId) async {
    return await _repository.fetchSellerProfileImage(sellerId);
  }
}
