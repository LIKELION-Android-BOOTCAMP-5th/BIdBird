/// 아이템 등록 관련 상수
/// 가격 제한
class ItemPriceLimits {
  /// 최소 가격 (10,000원)
  static const int minPrice = 10000;
  
  /// 최대 가격 (5,000,000원)
  static const int maxPrice = 5000000;
}

/// 텍스트 길이 제한
class ItemTextLimits {
  /// 제목 최대 길이 (20자)
  static const int maxTitleLength = 20;
  
  /// 설명 최대 길이 (1,000자)
  static const int maxDescriptionLength = 1000;
}

/// 이미지 제한
class ItemImageLimits {
  /// 최대 이미지 개수 (10장)
  static const int maxImageCount = 10;
  
  /// 최소 이미지 개수 (1장)
  static const int minImageCount = 1;
}

/// 입찰 단위 계산 기준
class ItemBidStepConstants {
  /// 입찰 단위 계산 기준 가격 (100,000원)
  /// 이 가격 이하일 때는 기본 단위를 사용
  static const int basePriceThreshold = 100000;
  
  /// 기본 입찰 단위 (1,000원)
  static const int defaultBidStep = 1000;
  
  /// 만원 단위 표시 기준 (10,000원)
  /// 이 값으로 나누어떨어지면 "만원" 단위로 표시
  static const int tenThousandUnit = 10000;
}

/// 경매 기간 관련 상수
class ItemAuctionDurationConstants {
  /// 경매 기간 옵션 (시간 단위)
  static const int duration4Hours = 4;
  static const int duration12Hours = 12;
  static const int duration24Hours = 24;
  
  /// 기본 경매 기간 (4시간)
  static const int defaultDuration = duration4Hours;
  
  /// 경매 기간 옵션 리스트 (문자열)
  static const List<String> durationOptions = [
    '4시간',
    '12시간',
    '24시간',
  ];
  
  /// 기본 경매 기간 옵션 (문자열)
  static const String defaultDurationOption = '4시간';
}

