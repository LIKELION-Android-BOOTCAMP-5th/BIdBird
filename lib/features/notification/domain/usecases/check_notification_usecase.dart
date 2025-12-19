import 'package:bidbird/features/notification/domain/repositories/notification_repository.dart';

class CheckNotificationUseCase {
  CheckNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call(String id) async {
    return _repository.checkNotification(id);
  }
}
