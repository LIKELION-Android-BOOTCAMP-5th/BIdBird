import '../../domain/entities/blacklisted_user_entity.dart';
import '../../domain/repositories/blacklist_repository.dart';
import '../datasources/blacklist_remote_data_source.dart';
import '../models/blacklisted_user_dto.dart';

class BlacklistRepositoryImpl implements BlacklistRepository {
  BlacklistRepositoryImpl({BlacklistRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? BlacklistRemoteDataSource();

  final BlacklistRemoteDataSource _remoteDataSource;

  @override
  Future<List<BlacklistedUserEntity>> fetchBlacklist() async {
    final userId = _remoteDataSource.currentUserId;
    if (userId == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final rows = await _remoteDataSource.fetchBlacklist(userId);

    final List<BlacklistedUserDto> items = [];
    for (final row in rows) {
      final BlacklistedUserDto? targetUser = _mapBlacklist(row);
      if (targetUser != null) {
        items.add(targetUser);
      }
    }
    return items.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<String?> blockUser(String targetUserId) async {
    final userId = _remoteDataSource.currentUserId;
    if (userId == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final response = await _remoteDataSource.blockUser(userId, targetUserId);
    return response?['id']?.toString();
  }

  @override
  Future<void> unblockUser(String targetUserId) async {
    final userId = _remoteDataSource.currentUserId;
    if (userId == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    await _remoteDataSource.unblockUser(userId, targetUserId);
  }

  BlacklistedUserDto? _mapBlacklist(dynamic row) {
    if (row is! Map<String, dynamic>) return null;

    final Map<String, dynamic>? targetUser =
        row['target_user'] as Map<String, dynamic>?;

    final String? targetId =
        targetUser?['id']?.toString() ?? row['target_user_id']?.toString();
    if (targetId == null || targetId.isEmpty) return null;

    final DateTime? createdAt = _parseDateTime(row['created_at']);

    return BlacklistedUserDto(
      targetUserId: targetId,
      nickName: targetUser?['nick_name']?.toString(),
      profileImageUrl: targetUser?['profile_image']?.toString(),
      registerUserId: row['id']?.toString(),
      createdAt: createdAt,
    );
  }

  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
