import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';

/// 첫 메시지 전송 유즈케이스
class FirstMessageUseCase {
  FirstMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<String?> call({
    required String itemId,
    String? message,
    required MessageType messageType,
    String? imageUrl,
  }) {
    return _repository.firstMessage(
      itemId: itemId,
      message: message,
      messageType: messageType,
      imageUrl: imageUrl,
    );
  }
}

