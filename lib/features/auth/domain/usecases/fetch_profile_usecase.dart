import '../entities/auth_set_profile_entity.dart';
import '../repositories/auth_set_profile_repository.dart';

/// 프로필 조회 유즈케이스
class FetchProfileUseCase {
  FetchProfileUseCase(this._repository);

  final AuthSetProfileRepository _repository;

  Future<AuthSetProfileEntity?> call() {
    return _repository.fetchProfile();
  }
}


