import '../../../../core/models/keywordType_entity.dart';
import '../entities/auth_set_profile_entity.dart';

/// Auth Set Profile 도메인 리포지토리 인터페이스
abstract class AuthSetProfileRepository {
  Future<AuthSetProfileEntity?> fetchProfile();
  
  Future<void> updateProfile({
    String? nickName,
    String? profileImageUrl,
    List<int>? keywordIds,
    bool deleteProfileImage = false,
  });
  
  Future<void> deleteAccount();
  
  Future<List<int>> fetchUserKeywordIds();
  
  Future<void> updateUserKeywords(List<int> keywordIds);
  
  Future<List<KeywordType>> getKeywordType();
}

