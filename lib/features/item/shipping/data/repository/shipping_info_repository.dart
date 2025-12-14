import 'package:bidbird/features/item/shipping/data/datasource/shipping_info_datasource.dart';

class ShippingInfoRepository {
  ShippingInfoRepository({ShippingInfoDatasource? datasource})
      : _datasource = datasource ?? ShippingInfoDatasource();

  final ShippingInfoDatasource _datasource;

  Future<void> saveShippingInfo({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  }) async {
    return await _datasource.saveShippingInfo(
      itemId: itemId,
      carrier: carrier,
      trackingNumber: trackingNumber,
    );
  }

  Future<Map<String, dynamic>?> getShippingInfo(String itemId) async {
    return await _datasource.getShippingInfo(itemId);
  }

  Future<void> updateShippingInfo({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  }) async {
    return await _datasource.updateShippingInfo(
      itemId: itemId,
      carrier: carrier,
      trackingNumber: trackingNumber,
    );
  }
}

