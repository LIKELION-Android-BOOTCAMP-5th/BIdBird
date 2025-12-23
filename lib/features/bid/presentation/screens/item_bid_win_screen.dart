import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/features/payment/payment_complete/presentation/screens/payment_complete_screen.dart';
import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/payment/portone_payment/presentation/screens/portone_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/bid/presentation/widgets/item_bid_result_body.dart';

class ItemBidWinScreen extends StatelessWidget {
  const ItemBidWinScreen({super.key, required this.item});

  final ItemBidWinEntity item;

  @override
  Widget build(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final String buyerTel = authVM.user?.phone_number ?? '';
    final bool isTradePaid = item.tradeStatusCode == 520;

    if (isTradePaid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go('/item/${item.itemId}');
      });

      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: BackgroundColor,
      body: SafeArea(
        child: ItemBidResultBody(
          item: item,
          title: '낙찰 되었습니다!',
          subtitle: '축하합니다! 낙찰되셨습니다.',
          icon: Icons.check_circle,
          iconColor: blueColor,
          onClose: () {
            // Navigator.push로 호출된 경우 (item_bottom_action_bar에서)
            // Navigator.pop을 사용하여 이전 화면(상세 화면)으로 돌아감
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // context.push로 호출된 경우 (알림, 홈 화면 등)
              // context.pop을 시도하고, 실패하면 context.go 사용
              if (context.canPop()) {
                context.pop();
              } else {
                // 상세 화면이 스택에 없으면 go를 사용
                // SharedPreferences에 플래그가 이미 저장되어 있으므로
                // 새로운 ViewModel이 생성되어도 중복 표시되지 않음
                context.go('/item/${item.itemId}');
              }
            }
          },
          actions: [
            Builder(
              builder: (context) {
                final buttonHeight = ResponsiveConstants.buttonHeight(context);
                final buttonFontSize = ResponsiveConstants.buttonFontSize(context);
                final textButtonFontSize = ResponsiveConstants.fontSizeMedium(context);
                final spacing = ResponsiveConstants.spacingSmall(context);
                
                return Column(
                  children: [
                    if (!isTradePaid) ...[
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: buttonHeight,
                      //   child: ElevatedButton(
                      //     onPressed: () async {
                      //       const appScheme = 'bidbird';
                      //
                      //       final request = ItemPaymentRequest(
                      //         itemId: item.itemId,
                      //         itemTitle: item.title,
                      //         amount: item.winPrice,
                      //         buyerTel: buyerTel,
                      //         appScheme: appScheme,
                      //       );
                      //
                      //       final result = await Navigator.push<bool>(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (_) => PortonePaymentScreen(
                      //             request: request,
                      //           ),
                      //         ),
                      //       );
                      //
                      //       if (!context.mounted) return;
                      //
                      //       if (result == true) {
                      //         if (!context.mounted) return;
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //             builder: (_) => PaymentCompleteScreen(item: item),
                      //           ),
                      //         );
                      //       } else if (result == false) {
                      //         if (!context.mounted) return;
                      //
                      //         showDialog<void>(
                      //           context: context,
                      //           barrierDismissible: true,
                      //           builder: (dialogContext) {
                      //             return AskPopup(
                      //               content: '결제가 취소되었거나 실패했습니다.\n다시 시도하시겠습니까?',
                      //               noText: '닫기',
                      //               yesText: '확인',
                      //               yesLogic: () async {
                      //                 Navigator.of(dialogContext).pop();
                      //               },
                      //             );
                      //           },
                      //         );
                      //       }
                      //     },
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: blueColor,
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: defaultBorder,
                      //       ),
                      //     ),
                      //     child: Text(
                      //       '결제하기',
                      //       style: TextStyle(
                      //         fontSize: buttonFontSize,
                      //         fontWeight: FontWeight.w700,
                      //         color: Colors.white,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // 임시: 결제 안내 박스 대신 간격만 유지
                      SizedBox(height: spacing),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChattingRoomScreen(itemId: item.itemId),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: const BorderSide(color: BorderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: defaultBorder,
                          ),
                        ),
                        child: Text(
                          '판매자에게 채팅하기',
                          style: TextStyle(
                            fontSize: textButtonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

