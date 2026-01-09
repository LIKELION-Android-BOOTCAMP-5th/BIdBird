import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationListRealtimeSubscriptionManager {
  RealtimeChannel? _notifyChannel;

  bool _isSubscribed = false;
  bool get isConnected => _isSubscribed;

  void setupRealtimeSubscription({
    required void Function(NotificationEntity notify) updateNotification,
    required void Function(String alarmId, bool isChecked) onUpdateChecked,
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
        // ✅ UPDATE: is_checked 변경만 반영
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'alarm',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentId,
          ),
          callback: (payload) {
            final newRec = payload.newRecord;
            final oldRec = payload.oldRecord;

            final String? id = newRec['id']?.toString();
            if (id == null || id.isEmpty) return;

            final String? deletedAt = newRec['deleted_at']?.toString();
            if (deletedAt != null) {
              return;
            } else {
              final bool? newChecked = newRec['is_checked'] as bool?;
              final bool? oldChecked = oldRec['is_checked'] as bool?;

              // is_checked 변화 없으면 무시
              if (newChecked == null) return;
              if (oldChecked != null && newChecked == oldChecked) return;

              onUpdateChecked(id, newChecked);
            }
          },
        )
        .subscribe((status, error) {
          debugPrint('📡 notifyChannel status: $status');

          if (status == RealtimeSubscribeStatus.subscribed) {
            _isSubscribed = true;
          }

          if (status == RealtimeSubscribeStatus.closed ||
              status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            _isSubscribed = false;
          }
        });

    print("알림 채널이 연결 되었습니다");
  }

  void closeSubscription() {
    if (_notifyChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_notifyChannel!);
    _notifyChannel = null;
    _isSubscribed = false;
  }
}
