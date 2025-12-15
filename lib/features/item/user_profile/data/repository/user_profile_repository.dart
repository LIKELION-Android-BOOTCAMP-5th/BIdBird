import 'package:bidbird/features/item/user_profile/model/user_profile_entity.dart';

import '../datasource/user_profile_datasource.dart';

class UserProfileRepository {
  UserProfileRepository({UserProfileDatasource? datasource})
      : _datasource = datasource ?? UserProfileDatasource();

  final UserProfileDatasource _datasource;

  Future<UserProfile> fetchUserProfile(String userId) {
    return _datasource.fetchUserProfile(userId);
  }
}
