import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatNetworkApiDatasource {
  final dio = Dio();
  ChatNetworkApiDatasource();
  Future<List<ChattingRoomEntity>> fetchChattingRoomList() async {
    final response = await SupabaseManager.shared.supabase.functions.invoke(
      'chatting/roomList',
      method: HttpMethod.get,
      headers: NetworkApiManager.headers,
    );
    if (response.data != null) {
      final List data = response.data;
      final List<ChattingRoomEntity> results = data.map((json) {
        return ChattingRoomEntity.fromJson(json);
      }).toList();

      return results;
    } else {
      return List.empty();
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfo(String itemId) async {
    try {
      final response = await SupabaseManager.shared.supabase.functions.invoke(
        'chatting/roomInfo',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
        body: {'itemId': itemId},
      );
      final data = response.data;
      final result = RoomInfoEntity.fromJson(data);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfoWithRoomId(String roomId) async {
    try {
      final response = await SupabaseManager.shared.supabase.functions.invoke(
        'chatting/roomInfoWithRoomId',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
        body: {'roomId': roomId},
      );
      final data = response.data;
      final result = RoomInfoEntity.fromJson(data);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<String?> firstMessage({
    required String itemId,
    String? message,
    required String messageType,
    String? imageUrl,
  }) async {
    if (messageType != "text" && messageType != "image") {
      return null;
    }

    try {
      final body = <String, dynamic>{
        'itemId': itemId,
        'message_type': messageType,
      };
      
      if (messageType == "text" && message != null) {
        body['message'] = message;
      } else if (messageType == "image" && imageUrl != null) {
        body['imageUrl'] = imageUrl;
      }

      final response = await SupabaseManager.shared.supabase.functions.invoke(
        'chatting/creatChattingRoom',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
        body: body,
      );
      
      if (response.data == null) return null;
      final data = response.data['room_id'] as String;
      return data;
    } catch (e) {
      return null;
    }
  }
}
