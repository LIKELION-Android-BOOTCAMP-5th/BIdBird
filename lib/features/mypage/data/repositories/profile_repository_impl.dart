import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_dto.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({ProfileRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSource();

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<ProfileEntity?> fetchProfile() async {
    final ProfileDto? dto = await _remoteDataSource.fetchProfile();
    return dto?.toEntity();
  }

  @override
  Future<void> updateProfile({
    String? nickName,
    String? profileImageUrl,
    bool deleteProfileImage = false,
  }) {
    return _remoteDataSource.updateProfile(
      nickName: nickName,
      profileImageUrl: profileImageUrl,
      deleteProfileImage: deleteProfileImage,
    );
  }

  @override
  Future<void> deleteAccount() {
    return _remoteDataSource.deleteAccount();
  }
}
