/// 입찰 제한 여부를 확인하는 도메인 게이트웨이
abstract class BidRestrictionGateway {
  /// true 이면 입찰 제한 상태
  Future<bool> isBidRestricted();
}
