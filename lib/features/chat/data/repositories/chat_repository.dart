import 'package:bidbird/features/chat/data/datasources/chat_supabase_datasource.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatSupabaseDatasource _chatDatasource = ChatSupabaseDatasource();
  @override
  Future<List<ChattingRoomEntity>> fetchChattingRoomList({
    int page = 1,
    int limit = 20,
  }) async {
    return await _chatDatasource.fetchChattingRoomList(
      page: page,
      limit: limit,
    );
  }

  @override
  Future<ChattingRoomEntity?> fetchNewChattingRoom(String roomId) async {
    return await _chatDatasource.fetchNewChattingRoom(roomId);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(
    String chattingRoomId,
  ) async {
    return await _chatDatasource.getMessages(
      chattingRoomId,
    );
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
        return await _chatDatasource.firstMessage(
          itemId: itemId,
          message: message,
          messageType: "text",
        );
      case MessageType.image:
        return await _chatDatasource.firstMessage(
          itemId: itemId,
          messageType: "image",
          imageUrl: imageUrl,
        );
      case MessageType.video:
        return await _chatDatasource.firstMessage(
          itemId: itemId,
          messageType: "image",
          imageUrl: imageUrl,
        );
    }
  }

  @override
  Future<RoomInfoEntity?> fetchRoomInfo(String itemId) async {
    return _chatDatasource.fetchRoomInfo(itemId);
  }

  @override
  Future<RoomInfoEntity?> fetchRoomInfoWithRoomId(String roomId) async {
    return _chatDatasource.fetchRoomInfoWithRoomId(roomId);
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

  @override
  Future<void> completeTrade(String itemId) async {
    await _chatDatasource.completeTrade(itemId);
  }

  @override
  Future<void> cancelTrade(
    String itemId,
    String reasonCode,
    bool isSellerFault,
  ) async {
    await _chatDatasource.cancelTrade(itemId, reasonCode, isSellerFault);
  }

  @override
  Future<void> submitTradeReview({
    required String itemId,
    required String toUserId,
    required String role,
    required double rating,
    required String comment,
  }) async {
    await _chatDatasource.submitTradeReview(
      itemId: itemId,
      toUserId: toUserId,
      role: role,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<bool> hasSubmittedReview(String itemId) async {
    return await _chatDatasource.hasSubmittedReview(itemId);
  }
}
