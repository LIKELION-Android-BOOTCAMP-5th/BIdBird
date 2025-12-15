import 'package:bidbird/features/item/bid/buy_now/gateway/bid_restriction_gateway.dart';

import '../datasource/bid_restriction_datasource.dart';

class BidRestrictionGatewayImpl implements BidRestrictionGateway {
  BidRestrictionGatewayImpl({BidRestrictionDatasource? datasource})
      : _datasource = datasource ?? BidRestrictionDatasource();

  final BidRestrictionDatasource _datasource;

  @override
  Future<bool> isBidRestricted() {
    return _datasource.isBidRestricted();
  }
}
