import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 메시지 목록 조회 유즈케이스
class GetMessagesUseCase {
  GetMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessageEntity>> call(String chattingRoomId, {bool forceRefresh = false}) {
    return _repository.getMessages(chattingRoomId, forceRefresh: forceRefresh);
  }
}

