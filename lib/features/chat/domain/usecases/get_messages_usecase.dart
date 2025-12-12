import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository _repository;

  GetMessagesUseCase(this._repository);

  Future<List<ChatMessageEntity>> call(String chattingRoomId) async {
    return await _repository.getMessages(chattingRoomId);
  }
}



