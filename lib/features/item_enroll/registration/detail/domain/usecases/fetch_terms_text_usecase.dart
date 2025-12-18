import 'package:bidbird/features/item_enroll/registration/detail/domain/repositories/item_registration_detail_repository.dart';

/// 약관 텍스트 조회 유즈케이스
class FetchTermsTextUseCase {
  FetchTermsTextUseCase(this._repository);

  final ItemRegistrationDetailRepository _repository;

  Future<String> call() {
    return _repository.fetchTermsText();
  }
}

