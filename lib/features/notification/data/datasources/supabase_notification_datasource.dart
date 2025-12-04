import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/notification/model/notification_entity.dart';

class SupabaseNotificationDatasource {
  Future<List<NotificationEntity>> fetchUser(String userId) async {
    final List<Map<String, dynamic>> data = await SupabaseManager
        .shared
        .supabase
        .from('alarm')
        .select()
        .eq('user_id', userId);

    if (data.length == 0) return List.empty();
    final List<NotificationEntity> results = data.map((json) {
      return NotificationEntity.fromJson(json);
    }).toList();
    return results;
  }
}
