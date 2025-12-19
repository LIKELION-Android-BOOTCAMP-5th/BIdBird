import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> fetchNotify();
  Future<void> checkNotification(String id);
  Future<void> checkAllNotification();
  Future<void> deleteNotification(String id);
  Future<void> deleteAllNotification();
}
