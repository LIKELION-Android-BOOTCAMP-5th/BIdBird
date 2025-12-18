import 'package:bidbird/features/payment/payment_history/data/repositories/payment_history_repository.dart';
import 'package:bidbird/features/payment/payment_history/domain/entities/payment_history_entity.dart';
import 'package:bidbird/features/payment/payment_history/domain/usecases/fetch_my_payments_usecase.dart';
import 'package:flutter/material.dart';

class PaymentHistoryViewModel extends ChangeNotifier {
  final FetchMyPaymentsUseCase _fetchMyPaymentsUseCase;

  PaymentHistoryViewModel({FetchMyPaymentsUseCase? fetchMyPaymentsUseCase})
      : _fetchMyPaymentsUseCase =
            fetchMyPaymentsUseCase ?? FetchMyPaymentsUseCase(PaymentHistoryRepositoryImpl());

  bool _loading = true;
  bool get loading => _loading;

  List<PaymentHistoryItem> _payments = [];
  List<PaymentHistoryItem> get payments => _payments;

  String? _error;
  String? get error => _error;

  /// 결제 내역 로드
  Future<void> loadPayments({String? itemId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _payments = await _fetchMyPaymentsUseCase(itemId: itemId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _payments = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 새로고침
  Future<void> refresh({String? itemId}) async {
    await loadPayments(itemId: itemId);
  }
}



