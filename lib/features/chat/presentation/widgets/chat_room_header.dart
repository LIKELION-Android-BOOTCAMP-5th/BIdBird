import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/role_badge.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:bidbird/features/report/presentation/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 채팅방 헤더 위젯
/// AppBar의 title과 actions를 포함
class ChatRoomHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChattingRoomViewmodel viewModel;

  const ChatRoomHeader({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 0,
      title: Builder(
        builder: (context) {
          // 현재 사용자가 판매자인지 확인
          final currentUserId =
              SupabaseManager.shared.supabase.auth.currentUser?.id;
          final isSeller =
              currentUserId != null &&
              viewModel.itemInfo != null &&
              viewModel.itemInfo!.sellerId == currentUserId;

          // 낙찰자 여부 확인
          final isTopBidder = viewModel.isTopBidder;
          final isOpponentTopBidder =
              isSeller && !isTopBidder && viewModel.hasTopBidder;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: () {
                    final userId = viewModel.roomInfo?.opponent.userId;
                    if (userId != null) {
                      context.push("/user/$userId");
                    }
                  },
                  child: Text(
                    viewModel.roomInfo != null
                        ? viewModel.roomInfo?.opponent.nickName ?? "사용자"
                        : (viewModel.fallbackOpponentName ??
                              (isSeller ? '구매자' : '판매자')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              if (isTopBidder || isOpponentTopBidder)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: RoleBadge(
                    isSeller: isSeller,
                    isTopBidder: isTopBidder,
                    isOpponentTopBidder: isOpponentTopBidder,
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        if (viewModel.notificationSetting != null)
          IconButton(
            onPressed: () {
              if (viewModel.notificationSetting != null) {
                viewModel.notificationToggle();
              }
            },
            icon: Icon(
              viewModel.notificationSetting?.isNotificationOn == true
                  ? Icons.notifications_none_outlined
                  : Icons.notifications_off_outlined,
              color: iconColor,
            ),
          ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (viewModel.roomInfo != null) {
              // 상대방 ID 찾기: itemInfo의 sellerId와 현재 사용자 비교
              final currentUserId =
                  SupabaseManager.shared.supabase.auth.currentUser?.id;
              String? targetUserId;

              if (currentUserId != null && viewModel.itemInfo != null) {
                // 현재 사용자가 판매자가 아니면 판매자를, 판매자면 buyer를 찾아야 함
                // 일단 판매자를 상대방으로 가정 (채팅방에서는 보통 상대방이 판매자)
                if (viewModel.itemInfo!.sellerId != currentUserId) {
                  targetUserId = viewModel.itemInfo!.sellerId;
                } else {
                  // 현재 사용자가 판매자인 경우, buyer_id를 찾아야 함
                  // tradeInfo에서 buyerId를 가져올 수 있음
                  targetUserId = viewModel.tradeInfo?.buyerId;
                }
              }

              if (targetUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportScreen(
                      itemId: viewModel.itemId,
                      itemTitle: viewModel.itemInfo?.title,
                      targetUserId: targetUserId!,
                      targetNickname: viewModel.roomInfo!.opponent.nickName,
                    ),
                  ),
                );
              }
            }
          },
          icon: Icon(Icons.warning, color: iconColor),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
