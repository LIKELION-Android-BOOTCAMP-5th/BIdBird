/// 날짜를 기본 포맷으로 반환 (예: 2025-12-24 13:05)
String formatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

/// 날짜를 한국어 형식으로 반환 (예: 2025년 1월 1일)
String formatDateKorean(DateTime dt) {
  return '${dt.year}년 ${dt.month}월 ${dt.day}일';
}

/// 날짜/시간을 짧은 점 표기로 반환 (예: 12.24 13:05)
String formatMonthDayTime(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$m.$d $h:$min';
}
