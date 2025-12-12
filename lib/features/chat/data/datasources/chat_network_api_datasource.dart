import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatNetworkApiDatasource {
  final dio = Dio();
  ChatNetworkApiDatasource() {}
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
    required String message_type,
    String? imageUrl,
  }) async {
    if (message_type == "text") {
      try {
        final response = await SupabaseManager.shared.supabase.functions.invoke(
          'chatting/creatChattingRoom',
          method: HttpMethod.post,
          headers: NetworkApiManager.useThisHeaders(),
          body: {
            'itemId': itemId,
            'message': message,
            'message_type': message_type,
          },
        );
        if (response.data == null) return null;
        final data = response.data['room_id'] as String;
        return data;
      } catch (e) {
        print('메세지 전송 실패 : ${e}');
      }
    } else if (message_type == "image") {
      try {
        final response = await SupabaseManager.shared.supabase.functions.invoke(
          'chatting/creatChattingRoom',
          method: HttpMethod.post,
          headers: NetworkApiManager.useThisHeaders(),
          body: {
            'itemId': itemId,
            'message_type': message_type,
            'imageUrl': imageUrl,
          },
        );
        if (response.data == null) return null;
        final data = response.data['room_id'] as String;
        return data;
      } catch (e) {
        print('메세지 전송 실패 : ${e}');
      }
    } else {
      print("메세지 타입이 잘못되었습니다.");
      return null;
    }
  }
}
