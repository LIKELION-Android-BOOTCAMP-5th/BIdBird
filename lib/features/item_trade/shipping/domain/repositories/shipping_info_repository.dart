/// Shipping Info 도메인 리포지토리 인터페이스
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



