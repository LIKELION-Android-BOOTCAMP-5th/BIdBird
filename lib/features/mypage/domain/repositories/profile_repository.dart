import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity?> fetchProfile();
  Future<void> updateProfile({
    String? nickName,
    String? profileImageUrl,
    bool deleteProfileImage = false,
  });
  Future<void> deleteAccount();
}
