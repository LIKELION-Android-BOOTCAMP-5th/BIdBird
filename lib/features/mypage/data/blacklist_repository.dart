import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/mypage/model/blacklist_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlacklistRepository {
  BlacklistRepository({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<List<BlacklistedUser>> fetchBlacklist() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final List<dynamic> rows = await _client
        .from('blacklist_by_user')
        .select(
          'id, target_user_id, created_at, '
          'target_user:users!blacklist_by_user_target_user_id_fkey(id, nick_name, profile_image)',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];

    final List<BlacklistedUser> items = [];
    for (final dynamic row in rows) {
      final BlacklistedUser? targetUser = _mapBlacklist(row);
      if (targetUser != null) {
        items.add(targetUser);
      }
    }
    return items;
  }

  Future<String?> blockUser(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final Map<String, dynamic>? response = await _client
        .from('blacklist_by_user')
        .insert({'user_id': user.id, 'target_user_id': targetUserId})
        .select('id, created_at')
        .maybeSingle();

    return response?['id']?.toString();
  }

  Future<void> unblockUser(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    await _client
        .from('blacklist_by_user')
        .delete()
        .eq('user_id', user.id)
        .eq('target_user_id', targetUserId);
  }

  BlacklistedUser? _mapBlacklist(dynamic row) {
    if (row is! Map<String, dynamic>) return null;

    final Map<String, dynamic>? targetUser =
        row['target_user'] as Map<String, dynamic>?; //다트일반패턴

    final String? targetId =
        targetUser?['id']?.toString() ?? row['target_user_id']?.toString();
    if (targetId == null || targetId.isEmpty) return null;

    final DateTime? createdAt = _parseDateTime(
      row['created_at'],
    ); //row['created_at'] as DateTime?//으로해도됨

    return BlacklistedUser(
      targetUserId: targetId,
      nickName: targetUser?['nick_name']?.toString(),
      profileImageUrl: targetUser?['profile_image']?.toString(),
      registerUserId: row['id']?.toString(),
      createdAt: createdAt,
      isBlocked: true,
    );
  }

  //DateTime이면 그대로 반환
  DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
