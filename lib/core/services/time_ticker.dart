import 'dart:async';

import 'package:flutter/foundation.dart';

/// 앱 전역에서 1초 단위로 시간을 브로드캐스트하는 티커
/// 각 아이템마다 Timer를 두는 대신, 이 티커 하나만 구독하도록 해 성능을 개선합니다.
class TimeTicker extends ChangeNotifier {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  TimeTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  DateTime get now => _now;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
