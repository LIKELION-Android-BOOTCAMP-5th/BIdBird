import '../entities/blacklisted_user_entity.dart';

abstract class BlacklistRepository {
  Future<List<BlacklistedUserEntity>> fetchBlacklist();
  Future<String?> blockUser(String targetUserId);
  Future<void> unblockUser(String targetUserId);
}
