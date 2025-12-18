import 'package:bidbird/features/payment/portone_payment/data/datasources/portone_payment_datasource.dart';
import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';
import 'package:bidbird/features/payment/portone_payment/domain/repositories/item_payment_repository.dart' as domain;

/// 결제 처리 리포지토리 구현체
class ItemPaymentRepositoryImpl implements domain.ItemPaymentRepository {
  ItemPaymentRepositoryImpl({PortonePaymentDatasource? datasource})
      : _datasource = datasource ?? PortonePaymentDatasource();

  final PortonePaymentDatasource _datasource;

  @override
  Future<bool> handlePaymentResult({
    required Map<String, dynamic> result,
    required ItemPaymentRequest request,
  }) async {
    // Portone 결제 결과 검증
    final String? errorCode = result['code'] as String?;
    final bool portoneSuccess = errorCode == null || errorCode.isEmpty;

    if (!portoneSuccess) {
      return false;
    }

    // 필수 필드 검증
    final txId = result['txId'] ?? result['transactionId'];
    final paymentId = result['paymentId'];
    
    if (txId == null || paymentId == null) {
      return false;
    }

    if (txId is! String || paymentId is! String) {
      return false;
    }

    if (txId.isEmpty || paymentId.isEmpty) {
      return false;
    }

    // 금액 검증
    final resultAmount = result['amount'] as int?;
    if (resultAmount != null && resultAmount != request.amount) {
      return false;
    }

    // 결제 처리
    return await _datasource.processPayment(
      itemId: request.itemId,
      txId: txId,
      paymentId: paymentId,
      amount: request.amount,
    );
  }
}



