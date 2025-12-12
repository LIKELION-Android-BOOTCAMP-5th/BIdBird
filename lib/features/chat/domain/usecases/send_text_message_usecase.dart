import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class SendTextMessageUseCase {
  final ChatRepository _repository;

  SendTextMessageUseCase(this._repository);

  Future<void> call(String roomId, String message) async {
    await _repository.sendTextMessage(roomId, message);
  }
}