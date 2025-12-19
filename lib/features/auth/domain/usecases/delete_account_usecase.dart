import '../repositories/auth_set_profile_repository.dart';

/// 계정 삭제 유즈케이스
class DeleteAccountUseCase {
  DeleteAccountUseCase(this._repository);

  final AuthSetProfileRepository _repository;

  Future<void> call() {
    return _repository.deleteAccount();
  }
}


