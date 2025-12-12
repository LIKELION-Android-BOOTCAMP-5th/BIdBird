import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class GetRoomIdUseCase {
  final ChatRepository _repository;

  GetRoomIdUseCase(this._repository);

  Future<String?> call(String itemId) async {
    return await _repository.getRoomId(itemId);
  }
}


