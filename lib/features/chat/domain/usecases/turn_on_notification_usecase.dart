import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class TurnOnNotificationUseCase {
  final ChatRepository _repository;

  TurnOnNotificationUseCase(this._repository);

  Future<void> call(String roomId) async {
    await _repository.notificationOn(roomId);
  }
}



