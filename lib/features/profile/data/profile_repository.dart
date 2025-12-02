import '../../../core/supabase_manager.dart';

import '../viewmodel/profile_viewmodel.dart';

class ProfileRepository {
  final _client = SupabaseManager.shared.supabase;

  Future<Profile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null; //인증구현전임시
    }

    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return null; //프로필없을때발생
      }

      return Profile.fromMap(response);
    } catch (e) {
      throw Exception('Failed fetchCurrentProfile: $e'); //나중에팝업으로쓸것
    }
  }
}
