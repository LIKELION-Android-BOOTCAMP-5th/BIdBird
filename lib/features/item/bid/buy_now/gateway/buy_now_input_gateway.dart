import 'package:bidbird/features/item/bid/buy_now/model/buy_now_input_entity.dart';

/// 즉시 구매 도메인 게이트웨이
abstract class BuyNowInputGateway {
  Future<void> placeBid(BuyNowBidRequest request);
}
