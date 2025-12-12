import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class TurnOffNotificationUseCase {
  final ChatRepository _repository;

  TurnOffNotificationUseCase(this._repository);

  Future<void> call(String roomId) async {
    await _repository.notificationOff(roomId);
  }
}



