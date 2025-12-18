import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../datasources/user_profile_datasource.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({UserProfileDatasource? datasource})
      : _datasource = datasource ?? UserProfileDatasource();

  final UserProfileDatasource _datasource;

  @override
  Future<UserProfile> fetchUserProfile(String userId) {
    return _datasource.fetchUserProfile(userId);
  }
}



