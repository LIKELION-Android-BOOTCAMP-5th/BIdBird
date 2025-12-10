import 'dart:async';

import 'package:bidbird/core/managers/network_api_manager.dart';
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
    await Supabase.instance.client.functions.invoke(
      'chatting-heartbeat/update',
      method: HttpMethod.post,
      headers: NetworkApiManager.headers,
      body: {'roomId': roomId},
    );
  }
}

final heartbeatManager = HeartbeatManager();
