import 'package:bidbird/features/item_enroll/registration/detail/domain/repositories/item_registration_detail_repository.dart';

/// 상품 등록 확인 유즈케이스
class ConfirmRegistrationUseCase {
  ConfirmRegistrationUseCase(this._repository);

  final ItemRegistrationDetailRepository _repository;

  Future<void> call(String itemId) {
    return _repository.confirmRegistration(itemId);
  }
}

