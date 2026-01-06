import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/managers/supabase_manager.dart';
import '../models/profile_dto.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseManager.shared.supabase;

  final SupabaseClient _client;

  Future<ProfileDto?> fetchProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Failed fetchProfile');
    }

    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed fetchProfile');
    }

    return ProfileDto.fromMap(response);
  }

  Future<void> updateProfile({
    String? nickName,
    String? profileImageUrl,
    bool deleteProfileImage = false,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Failed updateProfile');
    }

    final Map<String, dynamic> updateData = {};

    if (nickName != null) {
      updateData['nick_name'] = nickName;
    }
    if (deleteProfileImage) {
      updateData['profile_image'] = null;
    } else if (profileImageUrl != null) {
      updateData['profile_image'] = profileImageUrl;
    }

    if (updateData.isEmpty) {
      return;
    }

    await _client.from('users').update(updateData).eq('id', user.id);
  }

  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Failed deleteAccount');
    }

    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Failed deleteAccount');
    }

    try {
      final result = await _client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      final data = result.data;

      if (data is Map && data['ok'] == true) {
        await _client.auth.signOut();
        return;
      }

      final reason = (data is Map) ? data['reason'] : null;

      //TRADE_STATUS_EXISTS로 오던것이 메세지가 변해서 SELLER_AUCTION_IN_PROGRESS로 와서 탈퇴가 안되는 오류가 나서 그냥 다 추가함
      if (reason == 'TRADE_STATUS_EXISTS') {
        throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
      }
      if (reason == 'SELLER_AUCTION_IN_PROGRESS') {
        throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
      }
      if (reason == 'BUYER_AUCTION_IN_PROGRESS') {
        throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
      }
      if (reason == 'PUBLIC_USER_ROW_NOT_FOUND') {
        throw Exception('Failed deleteAccount');
      }

      throw Exception('Failed deleteAccount');
    } catch (e) {
      if (e is FunctionException) {
        final details = e.details;

        if (details is Map) {
          final reason = details['reason'];

          if (reason == 'TRADE_STATUS_EXISTS') {
            throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
          }
          if (reason == 'SELLER_AUCTION_IN_PROGRESS') {
            throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
          }
          if (reason == 'BUYER_AUCTION_IN_PROGRESS') {
            throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
          }
          if (reason == 'PUBLIC_USER_ROW_NOT_FOUND') {
            throw Exception('Failed deleteAccount');
          }

          throw Exception('Failed deleteAccount');
        }
      }
      rethrow;
    }
  }
}
