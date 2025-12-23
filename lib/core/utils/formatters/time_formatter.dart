import 'package:intl/intl.dart';

/// 날짜를 간단한 포맷으로 반환 (예: 2025-12-24 13:05)
String formatDateTime(DateTime dt, {String pattern = 'yyyy-MM-dd HH:mm'}) {
  return DateFormat(pattern).format(dt);
}
