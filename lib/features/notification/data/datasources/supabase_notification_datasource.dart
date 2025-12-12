import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/notification/model/notification_entity.dart';

class SupabaseNotificationDatasource {
  final _client = SupabaseManager.shared.supabase;
  Future<List<NotificationEntity>> fetchNotify(String userId) async {
    final List<Map<String, dynamic>> data = await _client
        .from('alarm')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (data.length == 0) return List.empty();
    final List<NotificationEntity> results = data.map((json) {
      return NotificationEntity.fromJson(json);
    }).toList();
    return results;
  }

  Future<void> checkNotification(String id) async {
    try {
      await _client.from('alarm').update({'is_checked': true}).eq('id', id);
    } catch (e) {
      print("알림 확인 체크에 실패했습니다 : $e");
    }
  }

  Future<void> checkAllNotification() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      print("userId가 없습니다");
      return;
    }
    try {
      await _client
          .from('alarm')
          .update({'is_checked': true})
          .eq('user_id', currentUserId);
      print("전체 알림 확인 처리 되었습니다.");
    } catch (e) {
      print("전체 알림 확인 체크에 실패했습니다 : $e");
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _client.from('alarm').delete().eq('id', id);
      print("알림 삭제 처리 되었습니다.");
    } catch (e) {
      print("알림 삭제에 실패했습니다 : $e");
    }
  }

  Future<void> deleteAllNotification() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      print("userId가 없습니다");
      return;
    }
    try {
      await _client.from('alarm').delete().eq('user_id', currentUserId);
      print("전체 알림 삭제 처리 되었습니다.");
    } catch (e) {
      print("전체 알림 삭제에 실패했습니다 : $e");
    }
  }
}
