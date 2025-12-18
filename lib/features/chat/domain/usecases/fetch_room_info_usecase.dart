import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 채팅방 정보 조회 유즈케이스 (itemId로)
class FetchRoomInfoUseCase {
  FetchRoomInfoUseCase(this._repository);

  final ChatRepository _repository;

  Future<RoomInfoEntity?> call(String itemId) {
    return _repository.fetchRoomInfo(itemId);
  }
}

