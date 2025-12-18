import 'package:bidbird/features/item_trade/shipping/data/datasources/shipping_info_datasource.dart';
import 'package:bidbird/features/item_trade/shipping/domain/repositories/shipping_info_repository.dart' as domain;

/// Shipping Info 리포지토리 구현체
class ShippingInfoRepositoryImpl implements domain.ShippingInfoRepository {
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



