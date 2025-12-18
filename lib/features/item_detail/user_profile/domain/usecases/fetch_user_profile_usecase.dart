import 'package:bidbird/features/item_detail/user_profile/domain/entities/user_profile_entity.dart';
import 'package:bidbird/features/item_detail/user_profile/domain/repositories/user_profile_repository.dart';

/// 사용자 프로필 조회 유즈케이스
class FetchUserProfileUseCase {
  FetchUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile> call(String userId) {
    return _repository.fetchUserProfile(userId);
  }
}

