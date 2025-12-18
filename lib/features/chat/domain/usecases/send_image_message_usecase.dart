import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 이미지 메시지 전송 유즈케이스
class SendImageMessageUseCase {
  SendImageMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String roomId, String imageUrl) {
    return _repository.sendImageMessage(roomId, imageUrl);
  }
}

