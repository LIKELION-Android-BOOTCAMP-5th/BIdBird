import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class GetOlderMessagesUseCase {
  final ChatRepository _repository;

  GetOlderMessagesUseCase(this._repository);

  Future<List<ChatMessageEntity>> call(
    String chattingRoomId,
    String beforeCreatedAtIso, {
    int limit = 50,
  }) async {
    return await _repository.getOlderMessages(
      chattingRoomId,
      beforeCreatedAtIso,
      limit: limit,
    );
  }
}



