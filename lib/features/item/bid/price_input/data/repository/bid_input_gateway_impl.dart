import 'package:bidbird/features/item/bid/price_input/model/bottom_sheet_price_input_entity.dart';
import 'package:bidbird/features/item/bid/price_input/gateway/bid_input_gateway.dart';

import '../datasource/price_input_datasource.dart';

/// 일반 입찰 도메인 게이트웨이 구현체
class BidInputGatewayImpl implements BidInputGateway {
  BidInputGatewayImpl({PriceInputDatasource? datasource})
      : _datasource = datasource ?? PriceInputDatasource();

  final PriceInputDatasource _datasource;

  @override
  Future<void> placeBid(BidRequest request) {
    return _datasource.placeBid(request);
  }
}
