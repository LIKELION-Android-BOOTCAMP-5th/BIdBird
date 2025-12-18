import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 채팅방 목록 조회 유즈케이스
class FetchChattingRoomListUseCase {
  FetchChattingRoomListUseCase(this._repository);

  final ChatRepository _repository;

  Future<List<ChattingRoomEntity>> call({
    int page = 1,
    int limit = 20,
  }) {
    return _repository.fetchChattingRoomList(
      page: page,
      limit: limit,
    );
  }
}

