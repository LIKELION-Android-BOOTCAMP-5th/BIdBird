import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 채팅방 정보 조회 유즈케이스 (roomId로)
class FetchRoomInfoWithRoomIdUseCase {
  FetchRoomInfoWithRoomIdUseCase(this._repository);

  final ChatRepository _repository;

  Future<RoomInfoEntity?> call(String roomId) {
    return _repository.fetchRoomInfoWithRoomId(roomId);
  }
}

