import 'package:bidbird/features/item_enroll/registration/detail/domain/repositories/item_registration_detail_repository.dart';

/// 모든 이미지 URL 조회 유즈케이스
class FetchAllImageUrlsUseCase {
  FetchAllImageUrlsUseCase(this._repository);

  final ItemRegistrationDetailRepository _repository;

  Future<List<String>> call(String itemId) {
    return _repository.fetchAllImageUrls(itemId);
  }
}

