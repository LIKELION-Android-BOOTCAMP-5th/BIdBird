import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/managers/supabase_manager.dart';

class BlacklistRemoteDataSource {
  BlacklistRemoteDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchBlacklist(String userId) {
    return _client
        .from('blacklist_by_user')
        .select(
          'id, target_user_id, created_at, '
          'target_user:users!blacklist_by_user_target_user_id_fkey(id, nick_name, profile_image)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>?> blockUser(String userId, String targetUserId) {
    return _client
        .from('blacklist_by_user')
        .insert({'user_id': userId, 'target_user_id': targetUserId})
        .select('id, created_at')
        .maybeSingle();
  }

  Future<void> unblockUser(String userId, String targetUserId) {
    return _client
        .from('blacklist_by_user')
        .delete()
        .eq('user_id', userId)
        .eq('target_user_id', targetUserId);
  }

  String? get currentUserId => _client.auth.currentUser?.id;
}
