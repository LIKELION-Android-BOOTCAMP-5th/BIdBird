import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class GetChattingRoomListUseCase {
  final ChatRepository _repository;

  GetChattingRoomListUseCase(this._repository);

  Future<List<ChattingRoomEntity>> call() async {
    return await _repository.fetchChattingRoomList();
  }
}