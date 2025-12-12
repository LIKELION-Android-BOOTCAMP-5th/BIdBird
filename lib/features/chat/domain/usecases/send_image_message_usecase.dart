import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class SendImageMessageUseCase {
  final ChatRepository _repository;

  SendImageMessageUseCase(this._repository);

  Future<void> call(String roomId, String imageUrl) async {
    await _repository.sendImageMessage(roomId, imageUrl);
  }
}


