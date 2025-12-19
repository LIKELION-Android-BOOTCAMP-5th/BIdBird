import 'package:bidbird/features/notification/domain/repositories/notification_repository.dart';

class DeleteAllNotificationUseCase {
  DeleteAllNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call() async {
    return _repository.deleteAllNotification();
  }
}
