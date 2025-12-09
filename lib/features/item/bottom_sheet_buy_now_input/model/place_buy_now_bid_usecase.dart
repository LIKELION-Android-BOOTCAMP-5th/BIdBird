import 'buy_now_input_entity.dart';
import 'buy_now_input_gateway.dart';

/// 즉시 구매 실행 유즈케이스
class PlaceBuyNowBidUseCase {
  PlaceBuyNowBidUseCase(this._gateway);

  final BuyNowInputGateway _gateway;

  Future<void> call(BuyNowBidRequest request) {
    return _gateway.placeBid(request);
  }
}
