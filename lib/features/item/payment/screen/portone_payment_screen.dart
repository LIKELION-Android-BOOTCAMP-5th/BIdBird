import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/payment/data/repository/item_payment_gateway_impl.dart';
import 'package:bidbird/features/item/payment/model/item_payment_request.dart';
import 'package:flutter/material.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';

class PortonePaymentScreen extends StatefulWidget {
  const PortonePaymentScreen({
    super.key,
    required this.request,
  });

  final ItemPaymentRequest request;

  @override
  State<PortonePaymentScreen> createState() => _PortonePaymentScreenState();
}

class _PortonePaymentScreenState extends State<PortonePaymentScreen> {
  String? _buyerName;
  String? _buyerPhone;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadDecryptedUser();
  }

  Future<void> _loadDecryptedUser() async {
    setState(() {
      _loadingUser = true;
    });

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;

      // 로그인 유저가 없으면 결제 진행 불가로 처리
      if (user == null) {
        setState(() {
          _buyerName = null;
          _buyerPhone = null;
          _loadingUser = false;
        });
        return;
      }

      final response = await supabase.functions.invoke('decrypt_user');
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
        setState(() {
          _buyerName = null;
          _buyerPhone = null;
          _loadingUser = false;
        });
        return;
      }

      setState(() {
        _buyerName = name;
        _buyerPhone = phone;
        _loadingUser = false;
      });
    } catch (e, st) {
      debugPrint('decrypt_user error: $e\n$st');
      setState(() {
        _buyerName = null;
        _buyerPhone = null;
        _loadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const String storeId = 'store-241926a0-bfe1-48eb-b467-dab78eb18dc3';
    const String channelKey =
        'channel-key-c5942f42-8e1c-4c5d-8a22-675313898226';

    if (_loadingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 사용자 정보 로딩 실패 또는 부족한 경우 에러 UI 노출
    if (_buyerName == null || _buyerPhone == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '사용자 정보를 불러오지 못했습니다.\n다시 시도해 주세요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDecryptedUser,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final String buyerName = _buyerName!;
    final String buyerPhone = _buyerPhone!;

    final String paymentId =
        'pay_${DateTime.now().millisecondsSinceEpoch}_${widget.request.itemId}';

    final customer = Customer(
      fullName: buyerName,
      phoneNumber: buyerPhone,
    );

    final paymentRequest = PaymentRequest(
      storeId: storeId,
      paymentId: paymentId,
      orderName: widget.request.itemTitle,
      totalAmount: widget.request.amount,
      currency: PaymentCurrency.KRW,
      channelKey: channelKey,
      payMethod: PaymentPayMethod.card,
      appScheme: widget.request.appScheme,
      customer: customer,
    );

    return Scaffold(
      body: PortonePayment(
        data: paymentRequest,
        initialChild: const Center(
          child: CircularProgressIndicator(),
        ),
        callback: (PaymentResponse result) async {
          final success = await ItemPaymentGatewayImpl().handlePaymentResult(
            result: result.toJson(),
            request: widget.request,
          );

          if (!mounted) return;
          Navigator.of(context).pop(success);
        },
        onError: (Object? error) {
          if (!mounted) return;
          Navigator.of(context).pop(false);
        },
      ),
    );
  }
}