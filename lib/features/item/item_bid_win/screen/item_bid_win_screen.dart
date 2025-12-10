import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/chat/screen/chatting_room_screen.dart';
import 'package:bidbird/features/payment/portone_payment/model/item_payment_request.dart';
import 'package:bidbird/features/payment/portone_payment/screen/portone_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../model/item_bid_win_entity.dart';
import '../widget/item_bid_result_body.dart';

class ItemBidSuccessScreen extends StatelessWidget {
  const ItemBidSuccessScreen({super.key, required this.item});

  final ItemBidWinEntity item;

  @override
  Widget build(BuildContext context) {
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
            context.go('/item/${item.itemId}');
          },
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  const buyerTel = '01012345678';
                  const appScheme = 'bidbird';

                  final request = ItemPaymentRequest(
                    itemId: item.itemId,
                    itemTitle: item.title,
                    amount: item.winPrice,
                    buyerTel: buyerTel,
                    appScheme: appScheme,
                  );

                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PortonePaymentScreen(
                        request: request,
                      ),
                    ),
                  );

                  if (!context.mounted) return;

                  if (result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('결제가 완료되었습니다.'),
                      ),
                    );
                  } else if (result == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('결제가 취소되었거나 실패했습니다.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: defaultBorder,
                  ),
                ),
                child: const Text(
                  '결제하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
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
                child: const Text(
                  '판매자에게 채팅하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
