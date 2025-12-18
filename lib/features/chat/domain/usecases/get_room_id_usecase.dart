import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 채팅방 ID 조회 유즈케이스
class GetRoomIdUseCase {
  GetRoomIdUseCase(this._repository);

  final ChatRepository _repository;

  Future<String?> call(String itemId) {
    return _repository.getRoomId(itemId);
  }
}

