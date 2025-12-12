// 리포지토리 사용법
// 1. networkApi datasource 혹은 supabase datasource
//
import 'package:bidbird/features/notification/data/datasources/supabase_notification_datasource.dart';
import 'package:bidbird/features/notification/model/notification_entity.dart';

class NotificationRepository {
  final SupabaseNotificationDatasource _supabaseNotificationDatasource =
      SupabaseNotificationDatasource();

  Future<List<NotificationEntity>> fetchNotify(String userId) async {
    return await _supabaseNotificationDatasource.fetchNotify(userId);
  }

  Future<void> checkNotification(String id) async {
    await _supabaseNotificationDatasource.checkNotification(id);
  }

  Future<void> checkAllNotification() async {
    await _supabaseNotificationDatasource.checkAllNotification();
  }

  Future<void> deleteNotification(String id) async {
    await _supabaseNotificationDatasource.deleteNotification(id);
  }

  Future<void> deleteAllNotification() async {
    await _supabaseNotificationDatasource.deleteAllNotification();
  }
}
