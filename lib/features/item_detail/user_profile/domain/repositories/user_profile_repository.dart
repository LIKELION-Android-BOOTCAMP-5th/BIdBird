import '../entities/user_profile_entity.dart';

abstract class UserProfileRepository {
  Future<UserProfile> fetchUserProfile(String userId);
}



