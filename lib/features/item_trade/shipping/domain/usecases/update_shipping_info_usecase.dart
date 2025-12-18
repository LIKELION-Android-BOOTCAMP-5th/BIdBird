import 'package:bidbird/features/item_trade/shipping/domain/repositories/shipping_info_repository.dart';

/// 배송 정보 수정 유즈케이스
class UpdateShippingInfoUseCase {
  UpdateShippingInfoUseCase(this._repository);

  final ShippingInfoRepository _repository;

  Future<void> call({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  }) {
    return _repository.updateShippingInfo(
      itemId: itemId,
      carrier: carrier,
      trackingNumber: trackingNumber,
    );
  }
}

