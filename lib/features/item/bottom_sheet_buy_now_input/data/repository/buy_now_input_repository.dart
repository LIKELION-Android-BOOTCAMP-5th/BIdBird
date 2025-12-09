import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/buy_now_input_entity.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/buy_now_input_gateway.dart';

import '../datasource/buy_now_input_data.dart';

/// BuyNowInput 도메인 게이트웨이 구현체
class BuyNowInputGatewayImpl implements BuyNowInputGateway {
  BuyNowInputGatewayImpl({BuyNowInputDatasource? datasource})
      : _datasource = datasource ?? BuyNowInputDatasource();

  final BuyNowInputDatasource _datasource;

  @override
  Future<void> placeBid(BuyNowBidRequest request) {
    return _datasource.placeBid(request);
  }
}
