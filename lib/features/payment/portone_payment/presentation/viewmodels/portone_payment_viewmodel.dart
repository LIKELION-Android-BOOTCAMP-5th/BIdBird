import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/payment/portone_payment/data/repositories/item_payment_repository.dart';
import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';
import 'package:bidbird/features/payment/portone_payment/domain/usecases/handle_payment_result_usecase.dart';
import 'package:flutter/material.dart';

class PortonePaymentViewModel extends ChangeNotifier {
  final HandlePaymentResultUseCase _handlePaymentResultUseCase;

  PortonePaymentViewModel({HandlePaymentResultUseCase? handlePaymentResultUseCase})
      : _handlePaymentResultUseCase =
            handlePaymentResultUseCase ?? HandlePaymentResultUseCase(ItemPaymentRepositoryImpl());

  bool _loadingUser = true;
  bool get loadingUser => _loadingUser;

  String? _buyerName;
  String? get buyerName => _buyerName;

  String? _buyerPhone;
  String? get buyerPhone => _buyerPhone;

  /// 사용자 정보 로드
  Future<void> loadDecryptedUser() async {
    _loadingUser = true;
    notifyListeners();

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      // 로그인 유저가 없으면 결제 진행 불가
      if (user == null) {
        _buyerName = null;
        _buyerPhone = null;
        _loadingUser = false;
        notifyListeners();
        return;
      }

      final response = await supabase.functions.invoke(
        'decrypt_user',
        body: <String, dynamic>{
          'user_id': user.id,
        },
      );
      final data = response.data;

      String? name;
      String? phone;

      if (data is Map) {
        name = data['name'] as String?;
        phone = data['phone_number'] as String?;

        if (name == null && phone == null && data['data'] is Map) {
          final inner = data['data'] as Map;
          name = inner['name'] as String?;
          phone = inner['phone_number'] as String?;
        }
      }

      // 이름 또는 전화번호가 없으면 결제 진행 중단
      if (name == null || name.isEmpty || phone == null || phone.isEmpty) {
        _buyerName = null;
        _buyerPhone = null;
      } else {
        _buyerName = name;
        _buyerPhone = phone;
      }
    } catch (e) {
      _buyerName = null;
      _buyerPhone = null;
    } finally {
      _loadingUser = false;
      notifyListeners();
    }
  }

  /// 결제 결과 처리
  Future<bool> handlePaymentResult({
    required Map<String, dynamic> result,
    required ItemPaymentRequest request,
  }) async {
    return await _handlePaymentResultUseCase(
      result: result,
      request: request,
    );
  }
}



