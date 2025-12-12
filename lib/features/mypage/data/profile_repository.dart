import '../../../core/managers/supabase_manager.dart';
import '../model/profile_model.dart';

class ProfileRepository {
  final _client = SupabaseManager.shared.supabase;

  Future<Profile?> fetchProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Failed fetchProfile'); //나중에팝업으로쓸것
      //return null; //예외상황
    }

    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed fetchProfile'); //나중에팝업으로쓸것
        //return null; //프로필없을때발생
      }

      return Profile.fromMap(response);
    } catch (e) {
      throw Exception('Failed fetchProfile: $e'); //나중에팝업으로쓸것
    }
  }

  Future<void> updateProfile({
    String? nickName,
    // String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Failed updateProfile'); //나중에팝업으로쓸것
    }

    final Map<String, dynamic> updateData = {};

    if (nickName != null) {
      updateData['nick_name'] = nickName;
    }
    // if (phoneNumber != null) {
    //   updateData['phone_number'] = phoneNumber;
    // }
    if (profileImageUrl != null) {
      updateData['profile_image'] = profileImageUrl;
    }

    if (updateData.isEmpty) {
      return;
    }

    try {
      await _client.from('users').update(updateData).eq('id', user.id);
    } catch (e) {
      throw Exception('Failed updateProfile: $e'); //나중에팝업으로쓸것
    }
  }

  Future<void> unregisterUser() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Failed unregisterUser'); //나중에팝업으로쓸것
    }

    // try {
    //   await _client
    //       .from('users')
    //       .update({
    //         'unregister_at': DateTime.now().millisecondsSinceEpoch,
    //       }) //밀리세컨드//사용자기기
    //       .eq('id', user.id); //추가로할처리들체크하고추가//한번에처리해야함
    // } catch (e) {
    //   throw Exception('Failed unregisterUser: $e'); //나중에팝업으로쓸것
    // }
  }
}
