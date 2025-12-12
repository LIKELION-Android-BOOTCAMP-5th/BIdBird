import 'package:bidbird/core/utils/item/item_registration_constants.dart';

/// 아이템 경매 기간 관련 유틸리티

/// 경매 기간(시간)을 문자열로 변환 (예: 4 -> "4시간")
String formatAuctionDuration(int hours) {
  return '$hours시간';
}

/// 경매 기간 문자열을 시간(숫자)로 변환 (예: "4시간" -> 4)
int parseAuctionDuration(String durationString) {
  switch (durationString) {
    case '4시간':
      return ItemAuctionDurationConstants.duration4Hours;
    case '12시간':
      return ItemAuctionDurationConstants.duration12Hours;
    case '24시간':
      return ItemAuctionDurationConstants.duration24Hours;
    default:
      // 숫자만 추출하여 반환
      final match = RegExp(r'(\d+)').firstMatch(durationString);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '') ?? 
               ItemAuctionDurationConstants.defaultDuration;
      }
      return ItemAuctionDurationConstants.defaultDuration;
  }
}

/// 경매 기간(시간)을 표시용 문자열로 변환
/// 4, 12, 24시간은 "4시간", "12시간", "24시간"으로, 그 외는 "X시간" 형식으로 반환
String formatAuctionDurationForDisplay(int hours) {
  if (hours == ItemAuctionDurationConstants.duration4Hours ||
      hours == ItemAuctionDurationConstants.duration12Hours ||
      hours == ItemAuctionDurationConstants.duration24Hours) {
    return formatAuctionDuration(hours);
  }
  return formatAuctionDuration(hours);
}

