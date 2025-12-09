import 'bottom_sheet_price_input_entity.dart';

/// 일반 입찰 도메인 게이트웨이
abstract class BidInputGateway {
  Future<void> placeBid(BidRequest request);
}
