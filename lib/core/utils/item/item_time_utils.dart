// 아이템 관련 시간 포맷팅 유틸리티

/// 경매 남은 시간을 HH:MM:SS 형식으로 포맷팅 (초 단위 포함)
String formatRemainingTime(DateTime finishTime) {
  final diff = finishTime.difference(DateTime.now());
  if (diff.isNegative) {
    return '00:00:00';
  }
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  final seconds = diff.inSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// 경매 남은 시간을 HH:MM 형식으로 포맷팅 (초 단위 제외)
String formatRemainingTimeShort(DateTime finishTime) {
  final diff = finishTime.difference(DateTime.now());
  if (diff.isNegative) {
    return '00:00';
  }
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

/// ISO 문자열을 상대 시간 문자열로 포맷팅 (예: "방금 전", "5분 전")
String formatRelativeTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  DateTime? time;
  try {
    time = DateTime.tryParse(isoString);
  } catch (_) {
    time = null;
  }
  if (time == null) return '';

  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) {
    return '방금 전';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}분 전';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}시간 전';
  } else {
    final days = diff.inDays;
    return '$days일 전';
  }
}

/// ISO 문자열을 날짜 형식으로 포맷팅 (예: "2024.12.13")
String formatDateFromIso(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$m.$d';
  } catch (_) {
    return '';
  }
}

/// DateTime을 날짜 형식으로 포맷팅 (예: "2024.12.13")
String formatDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}.$m.$d';
}

/// DateTime을 날짜와 시간 형식으로 포맷팅 (예: "2024.12.13 14:30")
String formatDateTime(DateTime date) {
  final dateStr = formatDate(date);
  final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return '$dateStr $timeStr';
}

/// ISO 문자열을 시간 형식으로 포맷팅 (예: "14:30")
String formatTimeFromIso(String isoString) {
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

/// ISO 문자열을 날짜와 시간 형식으로 포맷팅 (예: "2024-12-13 14:30")
String formatDateTimeFromIso(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;

    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  } catch (_) {
    return isoString;
  }
}