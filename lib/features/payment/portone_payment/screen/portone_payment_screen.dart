import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/payment/payment_error_messages.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/config/portone_config.dart';
import 'package:bidbird/features/payment/portone_payment/data/repository/item_payment_gateway.dart';
import 'package:bidbird/features/payment/portone_payment/data/repository/item_payment_gateway_impl.dart';
import 'package:bidbird/features/payment/portone_payment/model/item_payment_request.dart';
import 'package:flutter/material.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';

class PortonePaymentScreen extends StatefulWidget {
  PortonePaymentScreen({
    super.key,
    required this.request,
    ItemPaymentGateway? gateway,
  }) : gateway = gateway ?? ItemPaymentGatewayImpl();

  final ItemPaymentRequest request;
  final ItemPaymentGateway gateway;

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

      debugPrint('[PortonePayment] current user: \\${user?.id}');

      // 로그인 유저가 없으면 결제 진행 불가로 처리
      if (user == null) {
        setState(() {
          _buyerName = null;
          _buyerPhone = null;
          _loadingUser = false;
        });
        return;
      }

      final response = await supabase.functions.invoke(
        'decrypt_user',
        body: <String, dynamic>{
          'user_id': user.id,
        },
      );
      final data = response.data;

      debugPrint('[PortonePayment] decrypt_user response: \\${response.data}');

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
    if (_loadingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 사용자 정보 로딩 실패 또는 부족한 경우 에러 UI 노출
    if (_buyerName == null || _buyerPhone == null) {
      final fontSize = context.buttonFontSize;
      final buttonFontSize = context.fontSizeMedium;
      final spacing = context.screenPadding;
      
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  PaymentErrorMessages.loadUserInfoFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fontSize),
                ),
                SizedBox(height: spacing),
                ElevatedButton(
                  onPressed: _loadDecryptedUser,
                  child: Text(
                    PaymentErrorMessages.retry,
                    style: TextStyle(fontSize: buttonFontSize),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String buyerName = _buyerName!;
    final String buyerPhone = _buyerPhone!;

    final paymentRequest = _buildPaymentRequest(
      buyerName: buyerName,
      buyerPhone: buyerPhone,
    );

    return Scaffold(
      body: PortonePayment(
        data: paymentRequest,
        initialChild: const Center(
          child: CircularProgressIndicator(),
        ),
        callback: (PaymentResponse result) async {
          final success = await widget.gateway.handlePaymentResult(
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

  PaymentRequest _buildPaymentRequest({
    required String buyerName,
    required String buyerPhone,
  }) {
    final String paymentId =
        'pay_${DateTime.now().millisecondsSinceEpoch}_${widget.request.itemId}';

    final customer = Customer(
      fullName: buyerName,
      phoneNumber: buyerPhone,
    );

    return PaymentRequest(
      storeId: PortoneConfig.storeId,
      paymentId: paymentId,
      orderName: widget.request.itemTitle,
      totalAmount: widget.request.amount,
      currency: PaymentCurrency.KRW,
      channelKey: PortoneConfig.channelKey,
      payMethod: PaymentPayMethod.card,
      appScheme: widget.request.appScheme,
      customer: customer,
      customData: {
        'escrow': 'true',
      },
    );
  }
}