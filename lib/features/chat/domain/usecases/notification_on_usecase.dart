import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 채팅방 알림 켜기 유즈케이스
class NotificationOnUseCase {
  NotificationOnUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String roomId) {
    return _repository.notificationOn(roomId);
  }
}

