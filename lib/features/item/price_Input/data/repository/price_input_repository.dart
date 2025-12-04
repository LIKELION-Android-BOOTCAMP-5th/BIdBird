import 'package:bidbird/features/item/price_Input/model/price_input_entity.dart';

import '../datasource/price_input_data.dart';

class PriceInputRepository {
  PriceInputRepository({PriceInputDatasource? datasource})
      : _datasource = datasource ?? PriceInputDatasource();

  final PriceInputDatasource _datasource;

  Future<void> placeBid(BidRequest request) {
    return _datasource.placeBid(request);
  }
}
