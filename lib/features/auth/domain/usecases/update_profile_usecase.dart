import '../repositories/auth_set_profile_repository.dart';

/// 프로필 업데이트 유즈케이스
class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);

  final AuthSetProfileRepository _repository;

  Future<void> call({
    String? nickName,
    String? profileImageUrl,
    List<int>? keywordIds,
    bool deleteProfileImage = false,
  }) {
    return _repository.updateProfile(
      nickName: nickName,
      profileImageUrl: profileImageUrl,
      keywordIds: keywordIds,
      deleteProfileImage: deleteProfileImage,
    );
  }
}


