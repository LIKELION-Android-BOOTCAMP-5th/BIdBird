import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class GetRoomInfoWithRoomIdUseCase {
  final ChatRepository _repository;

  GetRoomInfoWithRoomIdUseCase(this._repository);

  Future<RoomInfoEntity?> call(String roomId) async {
    return await _repository.fetchRoomInfoWithRoomId(roomId);
  }
}