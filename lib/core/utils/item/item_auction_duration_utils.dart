import 'package:bidbird/core/utils/item/item_registration_constants.dart';

/// 아이템 경매 기간 관련 유틸리티

/// 경매 기간(시간)을 문자열로 변환 (예: 24 -> "1일")
String formatAuctionDuration(int hours) {
  if (hours % 24 == 0) {
    final days = hours ~/ 24;
    return '$days일';
  }
  return '$hours시간';
}

/// 경매 기간 문자열을 시간(숫자)로 변환 (예: "1일" -> 24, "4시간" -> 4)
int parseAuctionDuration(String durationString) {
  switch (durationString) {
    case '4시간':
      return ItemAuctionDurationConstants.duration4Hours;
    case '8시간':
      return ItemAuctionDurationConstants.duration8Hours;
    case '12시간':
      return ItemAuctionDurationConstants.duration12Hours;
    case '1일':
      return ItemAuctionDurationConstants.duration1Day;
    case '2일':
      return ItemAuctionDurationConstants.duration2Days;
    case '3일':
      return ItemAuctionDurationConstants.duration3Days;
    case '7일':
      return ItemAuctionDurationConstants.duration7Days;
    default:
      // 시간 단위 처리 (예: "4시간" -> 4)
      if (durationString.contains('시간')) {
        final match = RegExp(r'(\d+)').firstMatch(durationString);
        if (match != null) {
          final hours = int.tryParse(match.group(1) ?? '');
          if (hours != null) {
            return hours;
          }
        }
      }
      // 일 단위 처리 (예: "1일" -> 24시간)
      if (durationString.contains('일')) {
        final match = RegExp(r'(\d+)').firstMatch(durationString);
        if (match != null) {
          final days = int.tryParse(match.group(1) ?? '');
          if (days != null) {
            return days * 24; // 일을 시간으로 변환
          }
        }
      }
      return ItemAuctionDurationConstants.defaultDuration;
  }
}

/// 경매 기간(시간)을 표시용 문자열로 변환
/// 24, 48, 72, 168시간은 "1일", "2일", "3일", "7일"로 변환
String formatAuctionDurationForDisplay(int hours) {
  return formatAuctionDuration(hours);
}

