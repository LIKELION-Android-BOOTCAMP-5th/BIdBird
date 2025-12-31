String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  // 미래 시간인 경우 (Timezone Glitch 보정 Logic)
  // 기존에 KST(UTC+9) 시간을 UTC로 잘못 저장하여 9시간 미래로 인식되는 데이터가 존재함
  // 이를 보정하기 위해 5분 이상 미래인 경우 9시간을 빼서 다시 계산
  if (diff.inMinutes < -5) {
    final adjustedDate = dateTime.subtract(const Duration(hours: 9));
    final adjustedDiff = now.difference(adjustedDate);

    // 보정 후 과거 시간이 되었다면 정상 로직 수행
    if (!adjustedDiff.isNegative) {
      if (adjustedDiff.inSeconds < 60) {
        return "방금 전";
      } else if (adjustedDiff.inMinutes < 60) {
        return "${adjustedDiff.inMinutes}분 전";
      } else if (adjustedDiff.inHours < 24) {
        return "${adjustedDiff.inHours}시간 전";
      } else if (adjustedDiff.inDays < 7) {
        return "${adjustedDiff.inDays}일 전";
      } else {
        return "${adjustedDate.year}.${adjustedDate.month}.${adjustedDate.day}";
      }
    }
  }

  if (diff.isNegative) {
    // 5분 이내의 미래(클럭 스큐)거나 보정 후에도 미래인 경우
    return "방금 전";
  }

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
