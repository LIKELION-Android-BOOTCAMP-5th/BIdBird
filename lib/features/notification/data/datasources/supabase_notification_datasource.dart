import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseNotificationDatasource {
  final _client = SupabaseManager.shared.supabase;
  Future<List<NotificationEntity>> fetchNotify() async {
    debugPrint(
      '======= SupabaseNotificationDatasource fetchNotify() 호출 ========',
    );
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint('fetchNotify() 알림 없음');
      return List.empty();
    }
    try {
      final List<Map<String, dynamic>> data = await _client
          .from('alarm')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      if (data.length == 0) return List.empty();
      final List<NotificationEntity> results = data.map((json) {
        return NotificationEntity.fromJson(json);
      }).toList();
      debugPrint('fetchNotify() 알림 응답 완료');
      return results;
    } on PostgrestException catch (e) {
      debugPrint(
        'fetchNotify() Postgrest error '
        'code=${e.code}, message=${e.message}',
      );
      return const [];
    } catch (e) {
      debugPrint('fetchNotify() 알림 응답 실패 : ${e}');
      return List.empty();
    }
  }

  Future<void> checkNotification(String id) async {
    try {
      await _client.from('alarm').update({'is_checked': true}).eq('id', id);
    } catch (e) {
      debugPrint("알림 확인 체크에 실패했습니다 : $e");
    }
  }

  Future<void> checkAllNotification() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint("userId가 없습니다");
      return;
    }
    try {
      await _client
          .from('alarm')
          .update({'is_checked': true})
          .eq('user_id', currentUserId);
      debugPrint("전체 알림 확인 처리 되었습니다.");
    } catch (e) {
      debugPrint("전체 알림 확인 체크에 실패했습니다 : $e");
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _client.from('alarm').delete().eq('id', id);
      debugPrint("알림 삭제 처리 되었습니다.");
    } catch (e) {
      debugPrint("알림 삭제에 실패했습니다 : $e");
    }
  }

  Future<void> deleteAllNotification() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint("userId가 없습니다");
      return;
    }
    try {
      await _client.from('alarm').delete().eq('user_id', currentUserId);
      debugPrint("전체 알림 삭제 처리 되었습니다.");
    } catch (e) {
      debugPrint("전체 알림 삭제에 실패했습니다 : $e");
    }
  }
}
