import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/chat/screen/chatting_room_screen.dart';
import 'package:flutter/material.dart';

import '../model/item_bid_win_entity.dart';

class ItemBidSuccessScreen extends StatelessWidget {
  const ItemBidSuccessScreen({super.key, required this.item});

  final ItemBidWinEntity item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.check_circle,
              size: 72,
              color: blueColor,
            ),
            const SizedBox(height: 24),
            const Text(
              '낙찰 되었습니다!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '축하합니다! 낙찰되셨습니다.',
              style: TextStyle(
                fontSize: 13,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: defaultBorder,
                  boxShadow: const [
                    BoxShadow(
                      color: shadowHigh,
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: ImageBackgroundColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(defaultRadius),
                            topRight: Radius.circular(defaultRadius),
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: item.images.isNotEmpty
                            ? Image.network(
                                item.images.first,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Text(
                                  '상품 이미지',
                                  style: TextStyle(color: iconColor),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '낙찰가',
                            style: TextStyle(
                              fontSize: 12,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.winPrice}원',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: 결제 플로우 연동
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
          ],
        ),
      ),
    );
  }
}
