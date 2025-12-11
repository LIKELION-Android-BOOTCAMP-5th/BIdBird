import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item/item_bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/features/item/item_bid_win/widget/item_bid_result_body.dart';
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
        child: ItemBidResultBody(
          item: item,
          title: '결제가 완료되었습니다!',
          subtitle: '판매자에게 결제 완료가 전달되었습니다.',
          icon: Icons.check_circle,
          iconColor: blueColor,
          onClose: () {
            Navigator.of(context).pop();
          },
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
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
                    borderRadius: BorderRadius.circular(8.7),
                  ),
                ),
                child: const Text(
                  '결제 내역 보기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // 홈으로 이동
                context.go('/home');
              },
              child: const Text(
                '홈으로 이동',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
