import 'package:bidbird/features/item_enroll/registration/detail/domain/repositories/item_registration_detail_repository.dart';

/// 첫 번째 이미지 URL 조회 유즈케이스
class FetchFirstImageUrlUseCase {
  FetchFirstImageUrlUseCase(this._repository);

  final ItemRegistrationDetailRepository _repository;

  Future<String?> call(String itemId) {
    return _repository.fetchFirstImageUrl(itemId);
  }
}

