import 'package:bidbird/features/item_trade/shipping/domain/repositories/shipping_info_repository.dart';

/// 배송 정보 저장 유즈케이스
class SaveShippingInfoUseCase {
  SaveShippingInfoUseCase(this._repository);

  final ShippingInfoRepository _repository;

  Future<void> call({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  }) {
    return _repository.saveShippingInfo(
      itemId: itemId,
      carrier: carrier,
      trackingNumber: trackingNumber,
    );
  }
}

