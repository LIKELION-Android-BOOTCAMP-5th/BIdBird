import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 텍스트 메시지 전송 유즈케이스
class SendTextMessageUseCase {
  SendTextMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String roomId, String message) {
    return _repository.sendTextMessage(roomId, message);
  }
}

