import 'package:bidbird/core/utils/item/item_registration_constants.dart';

/// 아이템 관련 가격 포맷팅 유틸리티

/// 가격을 세 자리마다 쉼표를 넣어 포맷팅 (예: 10000 -> "10,000")
String formatPrice(int price) {
  final buffer = StringBuffer();
  final text = price.toString();
  for (int i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

/// 문자열에서 숫자만 추출하여 세 자리마다 쉼표를 넣어 포맷팅
/// 아이템 등록 시 가격 입력 필드에서 사용
/// 예: "10,000원" -> "10,000", "abc123def" -> "123"
String formatNumber(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';

  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != digits.length - 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

/// 포맷된 가격 문자열에서 쉼표를 제거하고 int로 파싱
/// 예: "10,000" -> 10000, "1,234,567" -> 1234567
/// [formattedPrice] 쉼표가 포함된 가격 문자열
/// Returns: 파싱된 int 값
int parseFormattedPrice(String formattedPrice) {
  final digits = formattedPrice.replaceAll(',', '');
  return int.tryParse(digits) ?? 0;
}

/// 아이템 가격 관련 헬퍼 클래스
class ItemPriceHelper {
  /// 현재 가격에 따른 입찰 단위를 계산
  /// 
  /// [currentPrice] 현재 경매 가격
  /// Returns: 입찰 단위 (원)
  static int calculateBidStep(int currentPrice) {
    if (currentPrice <= ItemBidStepConstants.basePriceThreshold) {
      return ItemBidStepConstants.defaultBidStep;
    }

    final priceStr = currentPrice.toString();
    if (priceStr.length >= 3) {
      return int.parse(priceStr.substring(0, priceStr.length - 2));
    }

    return ItemBidStepConstants.defaultBidStep;
  }
}