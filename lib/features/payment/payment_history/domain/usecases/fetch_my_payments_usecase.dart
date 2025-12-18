import 'package:bidbird/features/payment/payment_history/domain/entities/payment_history_entity.dart';
import 'package:bidbird/features/payment/payment_history/domain/repositories/payment_history_repository.dart';

/// 내 결제 내역 조회 유즈케이스
class FetchMyPaymentsUseCase {
  FetchMyPaymentsUseCase(this._repository);

  final PaymentHistoryRepository _repository;

  Future<List<PaymentHistoryItem>> call({String? itemId}) {
    return _repository.fetchMyPayments(itemId: itemId);
  }
}

