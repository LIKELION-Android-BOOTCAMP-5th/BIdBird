import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

class GetRoomNotificationSettingUseCase {
  final ChatRepository _repository;

  GetRoomNotificationSettingUseCase(this._repository);

  Future<ChattingNotificationSetEntity?> call(String roomId) async {
    return await _repository.getRoomNotificationSetting(roomId);
  }
}



