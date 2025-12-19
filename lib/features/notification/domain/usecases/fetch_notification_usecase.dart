import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';
import 'package:bidbird/features/notification/domain/repositories/notification_repository.dart';

class FetchNotificationUseCase {
  FetchNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  Future<List<NotificationEntity>> call() async {
    return _repository.fetchNotify();
  }
}
