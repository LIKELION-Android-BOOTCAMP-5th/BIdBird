import 'dart:async';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeartbeatManager {
  Timer? _timer;

  void start(String roomId) {
    if (_timer != null) return; // already running

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(roomId),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _sendHeartbeat(String roomId) async {
    debugPrint("heartBeat 작동함");
    String authorizationKey =
        SupabaseManager.shared.supabase.auth.currentSession?.accessToken != null
        ? 'Bearer ${SupabaseManager.shared.supabase.auth.currentSession?.accessToken}'
        : 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5ZmdmaWNjZWpqZ3R2cG10a3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNTUwNjksImV4cCI6MjA3NzYzMTA2OX0.Ng9atODZnfRocZPtnIb74s6PLeIJ2HqqSaatj1HbRsc';
    await Supabase.instance.client.functions.invoke(
      'chatting-heartbeat/update',
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

final heartbeatManager = HeartbeatManager();
