/// 거래 상태 코드 상수
class TradeStatusCode {
  TradeStatusCode._();

  /// 결제 대기
  static const int paymentRequired = 510;

  /// 배송 대기 (결제 완료, 배송 정보 입력 대기)
  static const int shippingInfoRequired = 520;

  /// 거래 완료
  static const int completed = 550;
}

/// 경매 상태 코드 상수
class AuctionStatusCode {
  AuctionStatusCode._();

  /// 경매 시작 전
  static const int ready = 300;

  /// 경매 진행 중
  static const int inProgress = 310;

  /// 즉시 구매 결제 대기
  static const int instantBuyPaymentPending = 311;

  /// 경매 종료 (낙찰)
  static const int bidWon = 321;

  /// 즉시 구매 완료
  static const int instantBuyCompleted = 322;

  /// 유찰
  static const int failed = 323;
}



