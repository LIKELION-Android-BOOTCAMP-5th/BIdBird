import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 채팅방 알림 끄기 유즈케이스
class NotificationOffUseCase {
  NotificationOffUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String roomId) {
    return _repository.notificationOff(roomId);
  }
}

