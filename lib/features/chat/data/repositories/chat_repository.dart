import 'package:bidbird/features/chat/data/datasources/chat_network_api_datasource.dart';
import 'package:bidbird/features/chat/data/datasources/chat_supabase_datasource.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatNetworkApiDatasource _networkApiChatDatasource =
      ChatNetworkApiDatasource();
  final ChatSupabaseDatasource _chatDatasource = ChatSupabaseDatasource();
  @override
  Future<List<ChattingRoomEntity>> fetchChattingRoomList() async {
    return await _networkApiChatDatasource.fetchChattingRoomList();
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String chattingRoomId) async {
    return await _chatDatasource.getMessages(chattingRoomId);
  }

  @override
  Future<List<ChatMessageEntity>> getOlderMessages(
    String chattingRoomId,
    String beforeCreatedAtIso, {
    int limit = 50,
  }) async {
    return await _chatDatasource.getOlderMessages(
      roomId: chattingRoomId,
      beforeCreatedAtIso: beforeCreatedAtIso,
      limit: limit,
    );
  }

  @override
  Future<String?> getRoomId(String itemId) async {
    return await _chatDatasource.getRoomId(itemId);
  }

  @override
  Future<void> sendImageMessage(String roomId, String imageUrl) async {
    await _chatDatasource.sendImageMessage(roomId, imageUrl);
  }

  @override
  Future<void> sendTextMessage(String roomId, String message) async {
    await _chatDatasource.sendTextMessage(roomId, message);
  }

  @override
  Future<String?> firstMessage({
    required String itemId,
    String? message,
    required MessageType messageType,
    String? imageUrl,
  }) async {
    switch (messageType) {
      case MessageType.text:
        return await _networkApiChatDatasource.firstMessage(
          itemId: itemId,
          message: message,
          messageType: "text",
        );
      case MessageType.image:
        return await _networkApiChatDatasource.firstMessage(
          itemId: itemId,
          messageType: "image",
          imageUrl: imageUrl,
        );
      case MessageType.video:
        return await _networkApiChatDatasource.firstMessage(
          itemId: itemId,
          messageType: "image",
          imageUrl: imageUrl,
        );
    }
  }

  @override
  Future<RoomInfoEntity?> fetchRoomInfo(String itemId) async {
    return _networkApiChatDatasource.fetchRoomInfo(itemId);
  }

  @override
  Future<RoomInfoEntity?> fetchRoomInfoWithRoomId(String roomId) async {
    return _networkApiChatDatasource.fetchRoomInfoWithRoomId(roomId);
  }

  @override
  Future<ChattingNotificationSetEntity?> getRoomNotificationSetting(
    String roomId,
  ) async {
    return _chatDatasource.getRoomNotificationSetting(roomId);
  }

  @override
  Future<void> notificationOff(String roomId) async {
    await _chatDatasource.notificationOff(roomId);
  }

  @override
  Future<void> notificationOn(String roomId) async {
    await _chatDatasource.notificationOn(roomId);
  }
}
