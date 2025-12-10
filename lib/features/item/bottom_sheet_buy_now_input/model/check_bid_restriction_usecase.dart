import 'bid_restriction_gateway.dart';

/// 현재 사용자 입찰 제한 여부를 확인하는 유즈케이스
class CheckBidRestrictionUseCase {
  CheckBidRestrictionUseCase(this._gateway);

  final BidRestrictionGateway _gateway;

  Future<bool> call() {
    return _gateway.isBidRestricted();
  }
}
