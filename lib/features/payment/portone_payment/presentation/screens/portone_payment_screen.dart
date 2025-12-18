import 'dart:math';

import 'package:bidbird/core/utils/payment/payment_error_messages.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/config/portone_config.dart';
import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';
import 'package:bidbird/features/payment/portone_payment/presentation/viewmodels/portone_payment_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:provider/provider.dart';

class PortonePaymentScreen extends StatelessWidget {
  const PortonePaymentScreen({
    super.key,
    required this.request,
  });

  final ItemPaymentRequest request;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PortonePaymentViewModel()..loadDecryptedUser(),
      child: Consumer<PortonePaymentViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.loadingUser) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // 사용자 정보 로딩 실패 또는 부족한 경우 에러 UI 노출
          if (viewModel.buyerName == null || viewModel.buyerPhone == null) {
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
                        onPressed: () => viewModel.loadDecryptedUser(),
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

          final String buyerName = viewModel.buyerName!;
          final String buyerPhone = viewModel.buyerPhone!;

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
                final success = await viewModel.handlePaymentResult(
                  result: result.toJson(),
                  request: request,
                );

                if (!context.mounted) return;
                Navigator.of(context).pop(success);
              },
              onError: (Object? error) {
                if (!context.mounted) return;
                Navigator.of(context).pop(false);
              },
            ),
          );
        },
      ),
    );
  }

  PaymentRequest _buildPaymentRequest({
    required String buyerName,
    required String buyerPhone,
  }) {
    final String paymentId =
        'pay_${DateTime.now().millisecondsSinceEpoch}_${request.itemId}_${Random().nextInt(999999)}';

    final customer = Customer(
      fullName: buyerName,
      phoneNumber: buyerPhone,
    );

    return PaymentRequest(
      storeId: PortoneConfig.storeId,
      paymentId: paymentId,
      orderName: request.itemTitle,
      totalAmount: request.amount,
      currency: PaymentCurrency.KRW,
      channelKey: PortoneConfig.channelKey,
      payMethod: PaymentPayMethod.card,
      appScheme: request.appScheme,
      customer: customer,
      customData: {
        'escrow': 'true',
      },
    );
  }
}



