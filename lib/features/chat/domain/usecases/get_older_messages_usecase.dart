import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 이전 메시지 목록 조회 유즈케이스
class GetOlderMessagesUseCase {
  GetOlderMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessageEntity>> call(
    String chattingRoomId,
    String beforeCreatedAtIso, {
    int limit = 50,
  }) {
    return _repository.getOlderMessages(
      chattingRoomId,
      beforeCreatedAtIso,
      limit: limit,
    );
  }
}

