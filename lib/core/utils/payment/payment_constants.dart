/// 결제 관련 상수

/// 결제 상태 코드
class PaymentStatusCodes {
  /// 경매 낙찰 (321)
  static const int auctionWin = 321;
  
  /// 즉시 구매 (322)
  static const int instantBuy = 322;
}

/// 결제 상태 텍스트
class PaymentStatusTexts {
  /// 경매 낙찰
  static const String auctionWin = '경매 낙찰';
  
  /// 즉시 구매
  static const String instantBuy = '즉시 구매';
  
  /// 결제 완료
  static const String completed = '결제 완료';
}

/// 결제 상태 색상
class PaymentStatusColors {
  /// 완료 상태 배경색 (연한 초록)
  static const int completedBackground = 0xFFE6F7EC;
  
  /// 완료 상태 텍스트 색상 (초록)
  static const int completedText = 0xFF27AE60;
  
  /// 미완료 상태 배경색 (연한 빨강)
  static const int incompleteBackground = 0xFFFFEBEE;
  
  /// 미완료 상태 텍스트 색상 (빨강)
  static const int incompleteText = 0xFFFF5252;
}

