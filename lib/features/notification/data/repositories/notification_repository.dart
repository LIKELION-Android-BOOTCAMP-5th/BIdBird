// 리포지토리 사용법
// 1. networkApi datasource 혹은 supabase datasource
//
import 'package:bidbird/features/notification/data/datasources/supabase_notification_datasource.dart';
import 'package:bidbird/features/notification/model/notification_entity.dart';

class NotificationRepository {
  final SupabaseNotificationDatasource _supabaseNotificationDatasource =
      SupabaseNotificationDatasource();

  Future<List<NotificationEntity>> fetchUser(String userId) async {
    return await _supabaseNotificationDatasource.fetchUser(userId);
  }
}
