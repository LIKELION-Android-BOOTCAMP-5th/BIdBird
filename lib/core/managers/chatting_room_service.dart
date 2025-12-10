import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChattingRoomService {
  final supabase = Supabase.instance.client;

  Future<void> enterRoom(String roomId) async {
    print("ChattingRoomService enterRoom roomId : ${roomId}");
    try {
      await supabase.functions.invoke(
        'chatting/enter',
        method: HttpMethod.post,
        headers: NetworkApiManager.headers,
        body: {'roomId': roomId},
      );
    } catch (e) {
      print("enterRoom 실패 : ${e}");
    }
  }

  Future<void> leaveRoom(String roomId) async {
    await supabase.functions.invoke(
      'chatting/leave',
      method: HttpMethod.post,
      headers: NetworkApiManager.headers,
      body: {'roomId': roomId},
    );
  }
}

final chattingRoomService = ChattingRoomService();
