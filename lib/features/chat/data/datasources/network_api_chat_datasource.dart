import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/model/chatting_room_entity.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkApiChatDatasource {
  final dio = Dio();
  NetworkApiChatDatasource() {}
  Future<List<ChattingRoomEntity>> fetchChattingRoomList() async {
    String authorizationKey =
        SupabaseManager.shared.supabase.auth.currentSession?.accessToken != null
        ? 'Bearer ${SupabaseManager.shared.supabase.auth.currentSession?.accessToken}'
        : 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5ZmdmaWNjZWpqZ3R2cG10a3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNTUwNjksImV4cCI6MjA3NzYzMTA2OX0.Ng9atODZnfRocZPtnIb74s6PLeIJ2HqqSaatj1HbRsc';
    final response = await SupabaseManager.shared.supabase.functions.invoke(
      'chatting/roomList',
      method: HttpMethod.get,
      headers: {
        'Authorization': authorizationKey,
        'apikey': 'sb_publishable_NQq1CoDOtr9FkfOSod8VHA_aqMLFp0x',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    if (response.data != null) {
      final List data = response.data;
      print("${data.runtimeType}");
      final List<ChattingRoomEntity> results = data.map((json) {
        return ChattingRoomEntity.fromJson(json);
      }).toList();

      return results;
    } else {
      return List.empty();
    }
  }

  Future<String?> firstMessage({
    required String itemId,
    String? message,
    required String message_type,
    String? imageUrl,
  }) async {
    String authorizationKey =
        SupabaseManager.shared.supabase.auth.currentSession?.accessToken != null
        ? 'Bearer ${SupabaseManager.shared.supabase.auth.currentSession?.accessToken}'
        : 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5ZmdmaWNjZWpqZ3R2cG10a3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNTUwNjksImV4cCI6MjA3NzYzMTA2OX0.Ng9atODZnfRocZPtnIb74s6PLeIJ2HqqSaatj1HbRsc';
    if (message_type == "text") {
      try {
        final response = await SupabaseManager.shared.supabase.functions.invoke(
          'chatting/creatChattingRoom',
          method: HttpMethod.post,
          headers: {
            'Authorization': authorizationKey,
            'apikey': 'sb_publishable_NQq1CoDOtr9FkfOSod8VHA_aqMLFp0x',
            'Content-Type': 'application/json',
          },
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
          headers: {
            'Authorization': authorizationKey,
            'apikey': 'sb_publishable_NQq1CoDOtr9FkfOSod8VHA_aqMLFp0x',
            'Content-Type': 'application/json',
          },
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
