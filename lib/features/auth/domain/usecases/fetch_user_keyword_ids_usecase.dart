import '../repositories/auth_set_profile_repository.dart';

/// 사용자 키워드 ID 조회 유즈케이스
class FetchUserKeywordIdsUseCase {
  FetchUserKeywordIdsUseCase(this._repository);

  final AuthSetProfileRepository _repository;

  Future<List<int>> call() {
    return _repository.fetchUserKeywordIds();
  }
}


