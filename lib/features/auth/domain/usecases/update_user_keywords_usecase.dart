import '../repositories/auth_set_profile_repository.dart';

/// 사용자 키워드 업데이트 유즈케이스
class UpdateUserKeywordsUseCase {
  UpdateUserKeywordsUseCase(this._repository);

  final AuthSetProfileRepository _repository;

  Future<void> call(List<int> keywordIds) {
    return _repository.updateUserKeywords(keywordIds);
  }
}


