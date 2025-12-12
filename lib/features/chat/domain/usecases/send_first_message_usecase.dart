import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';

class SendFirstMessageUseCase {
  final ChatRepository _repository;

  SendFirstMessageUseCase(this._repository);

  Future<String?> call({
    required String itemId,
    String? message,
    required MessageType messageType,
    String? imageUrl,
  }) async {
    return await _repository.firstMessage(
      itemId: itemId,
      message: message,
      messageType: messageType,
      imageUrl: imageUrl,
    );
  }
}