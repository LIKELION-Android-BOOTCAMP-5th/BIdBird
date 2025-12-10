import 'package:supabase_flutter/supabase_flutter.dart';

class ChattingRoomService {
  final supabase = Supabase.instance.client;

  Future<void> enterRoom(String roomId) async {
    print("ChattingRoomService enterRoom roomId : ${roomId}");
    String authorizationKey = supabase.auth.currentSession?.accessToken != null
        ? 'Bearer ${supabase.auth.currentSession?.accessToken}'
        : 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5ZmdmaWNjZWpqZ3R2cG10a3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNTUwNjksImV4cCI6MjA3NzYzMTA2OX0.Ng9atODZnfRocZPtnIb74s6PLeIJ2HqqSaatj1HbRsc';

    try {
      await supabase.functions.invoke(
        'chatting/enter',
        method: HttpMethod.post,
        headers: {
          'Authorization': authorizationKey,
          'apikey': 'sb_publishable_NQq1CoDOtr9FkfOSod8VHA_aqMLFp0x',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'roomId': roomId},
      );
    } catch (e) {
      print("enterRoom 실패 : ${e}");
    }
  }

  Future<void> leaveRoom(String roomId) async {
    String authorizationKey = supabase.auth.currentSession?.accessToken != null
        ? 'Bearer ${supabase.auth.currentSession?.accessToken}'
        : 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5ZmdmaWNjZWpqZ3R2cG10a3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNTUwNjksImV4cCI6MjA3NzYzMTA2OX0.Ng9atODZnfRocZPtnIb74s6PLeIJ2HqqSaatj1HbRsc';

    await supabase.functions.invoke(
      'chatting/leave',
      method: HttpMethod.post,
      headers: {
        'Authorization': authorizationKey,
        'apikey': 'sb_publishable_NQq1CoDOtr9FkfOSod8VHA_aqMLFp0x',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'roomId': roomId},
    );
  }
}

final chattingRoomService = ChattingRoomService();
