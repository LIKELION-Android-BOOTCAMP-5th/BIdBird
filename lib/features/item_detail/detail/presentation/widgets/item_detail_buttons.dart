import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bidbird/core/widgets/item/components/buttons/modern_bid_button.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

/// 판매자에게 연락하기 버튼
/// [ModernBidButton]을 사용하여 일관된 스타일 제공
class ContactSellerButton extends StatelessWidget {
  const ContactSellerButton({
    super.key,
    required this.itemId,
    required this.itemTitle,
    required this.sellerId,
    required this.sellerName,
    required this.currentPrice,
  });

  final String itemId;
  final String itemTitle;
  final String sellerId;
  final String sellerName;
  final int currentPrice;

  @override
  Widget build(BuildContext context) {
    return ModernBidButton(
      text: '판매자에게 연락하기',
      icon: Icon(
        Icons.chat_bubble_outline,
        size: context.iconSizeSmall,
        color: Colors.white,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChattingRoomScreen(
              itemId: itemId,
              itemTitle: itemTitle,
              sellerUserId: sellerId,
              sellerName: sellerName,
              itemPrice: currentPrice,
            ),
          ),
        );
      },
    );
  }
}

/// 구매자에게 연락하기 버튼
class ContactBuyerButton extends StatelessWidget {
  const ContactBuyerButton({
    super.key,
    required this.itemId,
    required this.itemTitle,
    required this.sellerId, // 내 ID (판매자 ID)
    required this.sellerName, // 내 닉네임
    required this.currentPrice,
  });

  final String itemId;
  final String itemTitle;
  final String sellerId;
  final String sellerName;
  final int currentPrice;

  @override
  Widget build(BuildContext context) {
    return ModernBidButton(
      text: '구매자 연락하기',
      icon: Icon(
        Icons.chat_bubble_outline,
        size: context.iconSizeSmall,
        color: Colors.white,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChattingRoomScreen(
              itemId: itemId,
              itemTitle: itemTitle,
              sellerUserId: sellerId,
              sellerName: sellerName,
              itemPrice: currentPrice,
              isSellerMode: true,
            ),
          ),
        );
      },
    );
  }
}

/// 결제 내역 보기 버튼
class ViewPaymentsButton extends StatelessWidget {
  const ViewPaymentsButton({
    super.key,
    required this.itemId,
  });

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      text: '결제 내역 보기',
      onPressed: () {
        context.push('/payments?itemId=$itemId');
      },
    );
  }
}
