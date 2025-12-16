import 'package:bidbird/features/item/shipping/data/datasource/shipping_info_datasource.dart';

abstract class ShippingInfoRepository {
  Future<void> saveShippingInfo({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  });
  Future<Map<String, dynamic>?> getShippingInfo(String itemId);
  Future<void> updateShippingInfo({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  });
}

class ShippingInfoRepositoryImpl implements ShippingInfoRepository {
  ShippingInfoRepositoryImpl({ShippingInfoDatasource? datasource})
      : _datasource = datasource ?? ShippingInfoDatasource();

  final ShippingInfoDatasource _datasource;

  @override
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

  @override
  Future<Map<String, dynamic>?> getShippingInfo(String itemId) async {
    return await _datasource.getShippingInfo(itemId);
  }

  @override
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

