import 'package:bidbird/features/chat/data/datasources/chat_network_api_datasource.dart';
import 'package:bidbird/features/chat/data/datasources/chat_supabase_datasource.dart';
import 'package:bidbird/features/chat/model/chat_message_entity.dart';
import 'package:bidbird/features/chat/model/chatting_room_entity.dart';
import 'package:bidbird/features/chat/model/room_info_entity.dart';
import 'package:bidbird/features/chat/viewmodel/chatting_room_viewmodel.dart';

class ChatRepositorie {
  final ChatNetworkApiDatasource _networkApiChatDatasource =
      ChatNetworkApiDatasource();
  final ChatSupabaseDatasource _chatDatasource = ChatSupabaseDatasource();
  Future<List<ChattingRoomEntity>> fetchChattingRoomList() async {
    return await _networkApiChatDatasource.fetchChattingRoomList();
  }

  Future<List<ChatMessageEntity>> getMessages(String chattingRoomId) async {
    print("리포지토리에서 메세지 fetch");
    return await _chatDatasource.getMessages(chattingRoomId);
  }

  Future<String?> getRoomId(String itemId) async {
    return await _chatDatasource.getRoomId(itemId);
  }

  Future<void> sendImageMessage(String roomId, String imageUrl) async {
    await _chatDatasource.sendImageMessage(roomId, imageUrl);
  }

  Future<void> sendTextMessage(String roomId, String message) async {
    await _chatDatasource.sendTextMessage(roomId, message);
  }

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
          message_type: "text",
        );
      case MessageType.image:
        return await _networkApiChatDatasource.firstMessage(
          itemId: itemId,
          message_type: "image",
          imageUrl: imageUrl,
        );
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfo(String itemId) async {
    return _networkApiChatDatasource.fetchRoomInfo(itemId);
  }
}
