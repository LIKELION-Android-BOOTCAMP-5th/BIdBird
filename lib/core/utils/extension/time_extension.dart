String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) {
    return "방금 전";
  } else if (diff.inMinutes < 60) {
    return "${diff.inMinutes}분 전";
  } else if (diff.inHours < 24) {
    return "${diff.inHours}시간 전";
  } else if (diff.inDays < 7) {
    return "${diff.inDays}일 전";
  } else {
    return "${dateTime.year}.${dateTime.month}.${dateTime.day}";
  }
}

extension StringToChatTimeAgo on String {
  String toTimesAgo() {
    return timeAgo(this.toDateTime());
  }
}

// 문자열 -> DateTime
extension StringToDateTime on String {
  // "2022-10-23T00:00:00".toDateTime()
  DateTime toDateTime() {
    return DateTime.parse(this);
  }
}

extension DateTimeToString on DateTime {
  String toDateString() {
    return "${this.year}년 ${this.month}월 ${this.day} 일";
  }
}
