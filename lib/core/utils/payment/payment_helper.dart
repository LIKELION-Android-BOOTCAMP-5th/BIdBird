import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/features/payment/payment_complete/screen/payment_complete_screen.dart';
import 'package:bidbird/features/payment/portone_payment/model/item_payment_request.dart';
import 'package:bidbird/features/payment/portone_payment/screen/portone_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> handlePayment({
  required BuildContext context,
  required String itemId,
  required String itemTitle,
  required int amount,
  int? tradeStatusCode,
}) async {
  final authVM = context.read<AuthViewModel>();
  final String buyerTel = authVM.user?.phone_number ?? '';
  const appScheme = 'bidbird';

  final request = ItemPaymentRequest(
    itemId: itemId,
    itemTitle: itemTitle,
    amount: amount,
    buyerTel: buyerTel,
    appScheme: appScheme,
  );

  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => PortonePaymentScreen(request: request),
    ),
  );

  if (!context.mounted) return;

  if (result == true) {
    // 결제 성공 시 결제 완료 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentCompleteScreen(
          item: ItemBidWinEntity(
            itemId: itemId,
            title: itemTitle,
            images: [],
            winPrice: amount,
            tradeStatusCode: tradeStatusCode,
          ),
        ),
      ),
    );
  } else if (result == false) {
    // 결제 실패 시 에러 다이얼로그 표시
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AskPopup(
          content: '결제가 취소되었거나 실패했습니다.\n다시 시도하시겠습니까?',
          noText: '닫기',
          yesText: '확인',
          yesLogic: () async {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}

