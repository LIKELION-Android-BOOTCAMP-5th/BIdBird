import 'package:bidbird/features/item/bottom_sheet_price_Input/model/bottom_sheet_price_input_entity.dart';

import '../datasource/bottom_sheet_price_input_data.dart';

class PriceInputRepository {
  PriceInputRepository({PriceInputDatasource? datasource})
      : _datasource = datasource ?? PriceInputDatasource();

  final PriceInputDatasource _datasource;

  Future<void> placeBid(BidRequest request) {
    return _datasource.placeBid(request);
  }
}
