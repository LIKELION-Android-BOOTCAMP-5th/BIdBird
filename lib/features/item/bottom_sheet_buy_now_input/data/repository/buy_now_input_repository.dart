import 'package:bidbird/features/item/bottom_sheet_buy_now_input/model/buy_now_input_entity.dart';

import '../datasource/buy_now_input_data.dart';

class BuyNowInputRepository {
  BuyNowInputRepository({BuyNowInputDatasource? datasource})
      : _datasource = datasource ?? BuyNowInputDatasource();

  final BuyNowInputDatasource _datasource;

  Future<void> placeBid(BuyNowBidRequest request) {
    return _datasource.placeBid(request);
  }
}
