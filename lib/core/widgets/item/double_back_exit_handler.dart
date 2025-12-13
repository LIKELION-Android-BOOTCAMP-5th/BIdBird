import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DoubleBackExitHandler {
  DateTime? _lastPressedAt;

  bool onWillPop(BuildContext context) {
    final now = DateTime.now();

    if (_lastPressedAt == null ||
        now.difference(_lastPressedAt!) > const Duration(seconds: 1)) {
      _lastPressedAt = now;

      // 웹에서 제외
      // Fluttertoast.cancel();
      Fluttertoast.showToast(
        webShowClose: true,
        msg: "한 번 더 누르면 앱이 종료됩니다",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        // yOffset: 80,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14,
      );

      return false; // 앱 종료 막음
    }

    return true; // 앱 종료 허용
  }
}
