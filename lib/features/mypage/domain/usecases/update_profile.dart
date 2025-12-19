import '../repositories/profile_repository.dart';

class UpdateProfile {
  UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<void> call({
    String? nickName,
    String? profileImageUrl,
    bool deleteProfileImage = false,
  }) {
    return _repository.updateProfile(
      nickName: nickName,
      profileImageUrl: profileImageUrl,
      deleteProfileImage: deleteProfileImage,
    );
  }
}
