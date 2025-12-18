import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChattingRoomService {
  final supabase = Supabase.instance.client;

  Future<void> enterRoom(String roomId) async {
    try {
      await supabase.functions.invoke(
        'enter-chat-room',
        body: {'roomId': roomId},
      );
    } catch (e) {
      // 에러 발생 시 조용히 처리
    }
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      await supabase.functions.invoke(
        'leave-chat-room',
        body: {'roomId': roomId},
      );
    } catch (e) {
      rethrow;
    }
  }
}

final chattingRoomService = ChattingRoomService();
