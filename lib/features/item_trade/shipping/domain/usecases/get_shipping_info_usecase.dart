import 'package:bidbird/features/item_trade/shipping/domain/repositories/shipping_info_repository.dart';

/// 배송 정보 조회 유즈케이스
class GetShippingInfoUseCase {
  GetShippingInfoUseCase(this._repository);

  final ShippingInfoRepository _repository;

  Future<Map<String, dynamic>?> call(String itemId) {
    return _repository.getShippingInfo(itemId);
  }
}

