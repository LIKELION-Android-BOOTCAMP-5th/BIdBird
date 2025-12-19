import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/managers/supabase_manager.dart';
import '../../domain/entities/auth_set_profile_entity.dart';
import '../../domain/repositories/auth_set_profile_repository.dart' as domain;
import '../datasources/auth_set_profile_network_api_datasource.dart';
import '../../../home/domain/entities/keywordType_entity.dart';

/// Auth Set Profile 리포지토리 구현체
class AuthSetProfileRepositoryImpl implements domain.AuthSetProfileRepository {
  final _client = SupabaseManager.shared.supabase;

  @override
  Future<AuthSetProfileEntity?> fetchProfile() async {
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

      return AuthSetProfileEntity.fromMap(response);
    } catch (e) {
      throw Exception('Failed fetchProfile: $e'); //나중에팝업으로쓸것
    }
  }

  @override
  Future<void> updateProfile({
    String? nickName,
    String? profileImageUrl,
    List<int>? keywordIds,
    bool deleteProfileImage = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Failed updateProfile');

    final Map<String, dynamic> updateData = {};
    if (nickName != null) updateData['nick_name'] = nickName;
    if (deleteProfileImage) {
      updateData['profile_image'] = null;
    } else if (profileImageUrl != null) {
      updateData['profile_image'] = profileImageUrl;
    }

    // if (keywordIds != null) {
    //   updateData['keyword_code'] = keywordIds; // users 테이블에 컬럼 존재 시
    // }

    if (updateData.isEmpty) return;

    try {
      await _client.from('users').update(updateData).eq('id', user.id);
    } catch (e) {
      throw Exception('Failed updateProfile: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Failed deleteAccount'); //나중에팝업으로쓸것
    }

    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Failed deleteAccount'); //나중에팝업으로쓸것
    }

    try {
      final result = await _client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        // body: {},
      );

      final data = result.data;

      if (data is Map && data['ok'] == true) {
        await _client.auth.signOut(); //Supabase 세션 정리

        //나중에만들기
        //로컬 상태 정리
        //SharedPreferences

        return;
      }

      //실패
      //이부분은엣지펑션이200, ok:false를주게세팅하면할수있는방법임
      //Supabase Flutter/Dart의functions.invoke()는 2xx가 아니면 바로 예외를 던져서 아래처럼 안됨
      //FunctionException은Supabase의클라이언트라이브러리에서정의된예외타입//(e is FunctionException)//급한대로이렇게써서해결
      final reason = (data is Map) ? data['reason'] : null;

      if (reason == 'TRADE_STATUS_EXISTS') {
        throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
      }
      if (reason == 'PUBLIC_USER_ROW_NOT_FOUND') {
        throw Exception('Failed deleteAccount');
      }

      throw Exception('Failed deleteAccount'); //${data ?? result.data}
      // } on FunctionException catch (e) {
    } catch (e) {
      print('ERROR: $e');
      if (e is FunctionException) {
        final details =
            e.details; //status: 409, details: {ok: false, reason: ...}처럼나옴

        if (details is Map) {
          final reason = details['reason'];

          if (reason == 'TRADE_STATUS_EXISTS') {
            throw Exception('진행 중인 경매가 있을 때는 탈퇴할 수 없습니다.');
          }
          if (reason == 'PUBLIC_USER_ROW_NOT_FOUND') {
            throw Exception('Failed deleteAccount');
          }

          throw Exception('Failed deleteAccount');
        }

        throw Exception('Failed deleteAccount})');
      }
    }
  }

  @override
  Future<List<int>> fetchUserKeywordIds() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final response = await _client
        .from('user_keyword')
        .select('keyword_code')
        .eq('user_id', user.id);

    return response.map<int>((e) => e['keyword_code'] as int).toList();
  }

  @override
  Future<List<KeywordType>> getKeywordType() async {
    return await AuthSetProfileNetworkApiDatasource.shared.getKeywordType();
  }

  @override
  Future<void> updateUserKeywords(List<int> keywordIds) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // 1. 기존 키워드 삭제
    await _client.from('user_keyword').delete().eq('user_id', user.id);

    // 2. 새 키워드 삽입
    if (keywordIds.isNotEmpty) {
      final rows = keywordIds
          .map((keyword) => {'user_id': user.id, 'keyword_code': keyword})
          .toList();

      await _client.from('user_keyword').insert(rows);
    }
  }
}

