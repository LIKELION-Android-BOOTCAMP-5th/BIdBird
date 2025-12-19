import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationListRealtimeSubscriptionManager {
  final _supabase = SupabaseManager.shared.supabase;

  RealtimeChannel? _notifyChannel;

  void setupRealtimeSubscription({
    required void Function(NotificationEntity notify) updateNotification,
  }) {
    final currentId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentId == null) return;
    if (_notifyChannel != null) return;
    _notifyChannel = SupabaseManager.shared.supabase.channel('notification');
    _notifyChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alarm',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentId,
          ),
          callback: (payload) {
            final newNotify = payload.newRecord;
            final NotificationEntity newNotification =
                NotificationEntity.fromJson(newNotify);
            updateNotification(newNotification);
          },
        )
        .subscribe();

    print("알림 채널이 연결 되었습니다");
  }

  void closeSubscription() {
    if (_notifyChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_notifyChannel!);
    _notifyChannel = null;
  }
}
