import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/payment/payment_texts.dart';
import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/core/widgets/item/components/others/item_bid_result_body.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentCompleteScreen extends StatelessWidget {
  const PaymentCompleteScreen({
    super.key,
    required this.item,
  });

  final ItemBidWinEntity item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ItemBidResultBody(
            item: item,
            title: PaymentTexts.paymentCompleteTitle,
            subtitle: PaymentTexts.paymentCompleteSubtitle,
            icon: Icons.check_circle,
            iconColor: blueColor,
            onClose: () {
              Navigator.of(context).pop();
            },
            actions: [
              Builder(
                builder: (context) {
                  final buttonHeight = context.buttonHeight;
                  final buttonFontSize = context.buttonFontSize;
                  final textButtonFontSize = context.fontSizeMedium;
                  final spacing = context.spacingSmall;
                  
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            // 결제한 해당 매물의 결제 내역만 보기
                            // 이 화면은 Navigator.push로 쌓여 있으므로 먼저 pop 후, 결제 상세 화면으로 이동
                            Navigator.of(context).pop();
                            context.go('/payments?itemId=${item.itemId}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blueColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: defaultBorder,
                            ),
                          ),
                          child: Text(
                            PaymentTexts.viewHistory,
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),
                      TextButton(
                        onPressed: () {
                          // 홈으로 이동
                          context.go('/home');
                        },
                        child: Text(
                          PaymentTexts.goHome,
                          style: TextStyle(
                            fontSize: textButtonFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
      ),
    );
  }
}
