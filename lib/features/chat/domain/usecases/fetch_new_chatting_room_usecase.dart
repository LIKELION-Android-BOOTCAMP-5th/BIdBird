import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class FetchNewChattingRoomUseCase {
  FetchNewChattingRoomUseCase(this._repository);
  final ChatRepository _repository;

  Future<ChattingRoomEntity?> call(String roomId) {
    return _repository.fetchNewChattingRoom(roomId);
  }
}
