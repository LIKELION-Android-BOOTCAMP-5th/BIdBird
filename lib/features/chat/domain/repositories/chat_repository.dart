import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';

/// 채팅 리포지토리 인터페이스
abstract class ChatRepository {
  Future<List<ChattingRoomEntity>> fetchChattingRoomList({
    int page = 1,
    int limit = 20,
  });
  Future<ChattingRoomEntity?> fetchNewChattingRoom(String roomId);
  Future<List<ChatMessageEntity>> getMessages(
    String chattingRoomId, {
    bool forceRefresh = false,
  });
  Future<List<ChatMessageEntity>> getOlderMessages(
    String chattingRoomId,
    String beforeCreatedAtIso, {
    int limit = 50,
  });
  Future<String?> getRoomId(String itemId);
  Future<void> sendImageMessage(String roomId, String imageUrl);
  Future<void> sendTextMessage(String roomId, String message);
  Future<String?> firstMessage({
    required String itemId,
    String? message,
    required MessageType messageType,
    String? imageUrl,
  });
  Future<RoomInfoEntity?> fetchRoomInfo(String itemId);
  Future<RoomInfoEntity?> fetchRoomInfoWithRoomId(String roomId);
  Future<ChattingNotificationSetEntity?> getRoomNotificationSetting(
    String roomId,
  );
  Future<void> notificationOff(String roomId);
  Future<void> notificationOn(String roomId);
  Future<void> completeTrade(String itemId);
  Future<void> cancelTrade(
    String itemId,
    String reasonCode,
    bool isSellerFault,
  );
  Future<void> submitTradeReview({
    required String itemId,
    required String toUserId,
    required String role,
    required double rating,
    required String comment,
  });
  Future<bool> hasSubmittedReview(String itemId);
}
