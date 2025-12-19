// 리포지토리 사용법
// 1. networkApi datasource 혹은 supabase datasource
//
import 'package:bidbird/features/notification/data/datasources/supabase_notification_datasource.dart';
import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';
import 'package:bidbird/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseNotificationDatasource _supabaseNotificationDatasource =
      SupabaseNotificationDatasource();
  @override
  Future<List<NotificationEntity>> fetchNotify() async {
    return await _supabaseNotificationDatasource.fetchNotify();
  }

  @override
  Future<void> checkNotification(String id) async {
    await _supabaseNotificationDatasource.checkNotification(id);
  }

  @override
  Future<void> checkAllNotification() async {
    await _supabaseNotificationDatasource.checkAllNotification();
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _supabaseNotificationDatasource.deleteNotification(id);
  }

  @override
  Future<void> deleteAllNotification() async {
    await _supabaseNotificationDatasource.deleteAllNotification();
  }
}
