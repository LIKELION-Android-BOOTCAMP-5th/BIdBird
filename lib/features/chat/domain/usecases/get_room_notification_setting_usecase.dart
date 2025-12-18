import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';

/// 채팅방 알림 설정 조회 유즈케이스
class GetRoomNotificationSettingUseCase {
  GetRoomNotificationSettingUseCase(this._repository);

  final ChatRepository _repository;

  Future<ChattingNotificationSetEntity?> call(String roomId) {
    return _repository.getRoomNotificationSetting(roomId);
  }
}

