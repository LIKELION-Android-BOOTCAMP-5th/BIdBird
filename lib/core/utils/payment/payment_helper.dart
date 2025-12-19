import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/payment/payment_complete/presentation/screens/payment_complete_screen.dart';
import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';
import 'package:bidbird/features/payment/portone_payment/presentation/screens/portone_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// TODO: 사업자 인증 후 아래 주석 해제
Future<void> handlePayment({
  required BuildContext context,
  required String itemId,
  required String itemTitle,
  required int amount,
  int? tradeStatusCode,
}) async {
  // 임시: 결제 기능 비활성화 - 안내 메시지만 표시
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('결제 기능 준비중입니다'),
    ),
  );
  return;
  
  // final authVM = context.read<AuthViewModel>();
  // final String buyerTel = authVM.user?.phone_number ?? '';
  // const appScheme = 'bidbird';
  //
  // final request = ItemPaymentRequest(
  //   itemId: itemId,
  //   itemTitle: itemTitle,
  //   amount: amount,
  //   buyerTel: buyerTel,
  //   appScheme: appScheme,
  // );
  //
  // final result = await Navigator.push<bool>(
  //   context,
  //   MaterialPageRoute(
  //     builder: (_) => PortonePaymentScreen(request: request),
  //   ),
  // );
  //
  // if (!context.mounted) return;
  //
  // if (result == true) {
  //   // 결제 성공 시 결제 완료 화면으로 이동
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => PaymentCompleteScreen(
  //         item: ItemBidWinEntity(
  //           itemId: itemId,
  //           title: itemTitle,
  //           images: [],
  //           winPrice: amount,
  //           tradeStatusCode: tradeStatusCode,
  //         ),
  //       ),
  //     ),
  //   );
  // } else if (result == false) {
  //   // 결제 실패 시 에러 다이얼로그 표시
  //   showDialog<void>(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (dialogContext) {
  //       return AskPopup(
  //         content: '결제가 취소되었거나 실패했습니다.\n다시 시도하시겠습니까?',
  //         noText: '닫기',
  //         yesText: '확인',
  //         yesLogic: () async {
  //           Navigator.of(dialogContext).pop();
  //         },
  //       );
  //     },
  //   );
  // }
}

