import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';
import 'package:bidbird/features/payment/portone_payment/domain/repositories/item_payment_repository.dart';

/// 결제 결과 처리 유즈케이스
class HandlePaymentResultUseCase {
  HandlePaymentResultUseCase(this._repository);

  final ItemPaymentRepository _repository;

  Future<bool> call({
    required Map<String, dynamic> result,
    required ItemPaymentRequest request,
  }) {
    return _repository.handlePaymentResult(
      result: result,
      request: request,
    );
  }
}

