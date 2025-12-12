import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class GetRoomInfoUseCase {
  final ChatRepository _repository;

  GetRoomInfoUseCase(this._repository);

  Future<RoomInfoEntity?> call(String itemId) async {
    return await _repository.fetchRoomInfo(itemId);
  }
}