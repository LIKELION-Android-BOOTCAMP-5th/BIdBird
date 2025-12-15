import 'package:bidbird/features/item/bid/price_input/model/bottom_sheet_price_input_entity.dart';
import 'package:bidbird/features/item/bid/price_input/gateway/bid_input_gateway.dart';

/// 일반 입찰 실행 유즈케이스
class PlaceBidUseCase {
  PlaceBidUseCase(this._gateway);

  final BidInputGateway _gateway;

  Future<void> call(BidRequest request) {
    return _gateway.placeBid(request);
  }
}
