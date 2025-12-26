import 'package:bidbird/core/utils/extension/time_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  bidSuccess,
  outbid,
  auctionStart,
  auctionEnd,
  win,
  payment,
  system,
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    this.thumbnailUrl,
    required this.status,
    this.date,
    this.onTap,
    this.onDelete,
    required this.body,
    required this.is_checked,
    required this.type,
  });

  final String title;
  final String? thumbnailUrl;
  final String status;
  final String? date;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool is_checked;
  final String? type;

  NotificationType parseNotificationType(String type) {
    switch (type) {
      case 'BID':
      case 'BID_SUCCESS':
        return NotificationType.bidSuccess;

      case 'OUTBID':
        return NotificationType.outbid;

      case 'AUCTION_START':
        return NotificationType.auctionStart;

      case 'AUCTION_END_SUCCESS':
      case 'AUCTION_FAILED':
        return NotificationType.auctionEnd;

      case 'WIN':
        return NotificationType.win;

      case 'PAID_SUCCESS':
        return NotificationType.payment;

      default:
        return NotificationType.system;
    }
  }

  Color notificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.bidSuccess:
        return Colors.blue;

      case NotificationType.outbid:
        return Colors.orange;

      case NotificationType.auctionStart:
        return Colors.indigo;

      case NotificationType.auctionEnd:
        return Colors.grey;

      case NotificationType.win:
        return Colors.amber;

      case NotificationType.payment:
        return Colors.green;

      case NotificationType.system:
        return Colors.purple;
    }
  }

  IconData notificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bidSuccess:
        return Icons.gavel;

      case NotificationType.outbid:
        return Icons.trending_up;

      case NotificationType.auctionStart:
        return Icons.play_circle_outline;

      case NotificationType.auctionEnd:
        return Icons.timer_off;

      case NotificationType.win:
        return Icons.emoji_events;

      case NotificationType.payment:
        return Icons.credit_card;

      case NotificationType.system:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedType = parseNotificationType(type!);
    final color = notificationColor(parsedType);
    final icon = notificationIcon(parsedType); // 아이콘 쓸 경우
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          boxShadow: const [
            BoxShadow(color: shadowHigh, blurRadius: 10, offset: Offset(0, 4)),
            BoxShadow(color: shadowLow, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👈 좌측 알림 타입 스트립
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color, // 알림 타입 컬러
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(defaultRadius),
                  bottomLeft: Radius.circular(defaultRadius),
                ),
              ),
            ),

            // 👉 메인 컨텐츠
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.screenPadding),
                child: Row(
                  spacing: context.spacingSmall,
                  children: [
                    // 🔔 알림 아이콘 (채팅의 프로필 영역 대체)
                    CircleAvatar(
                      radius: context.isLargeScreen() ? 28 : 24,
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(
                        icon, // notificationIcon(type)
                        color: color,
                        size: 22,
                      ),
                    ),

                    // 📄 텍스트 영역
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.fontSizeLarge,
                                  ),
                                ),
                              ),
                              if (date != null)
                                Text(
                                  date!.toTimesAgo(),
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: context.fontSizeSmall,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    body,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: context.fontSizeMedium,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                if (!is_checked)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: context.spacingSmall,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.spacingSmall,
                                        vertical: 4,
                                      ),
                                      height: 10,
                                      width: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // // ❌ 삭제 버튼
                    // IconButton(
                    //   icon: const Icon(Icons.close, size: 18),
                    //   onPressed: onDelete,
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Container(
// decoration: BoxDecoration(
// color: !is_checked ? Colors.white : Colors.white38,
// border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
// borderRadius: defaultBorder,
// boxShadow: const [
// BoxShadow(color: shadowHigh, blurRadius: 10, offset: Offset(0, 4)),
// BoxShadow(color: shadowLow, blurRadius: 4, offset: Offset(0, 1)),
// ],
// ),
// child: Stack(
// children: [
// Row(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// SizedBox(
// width: 96,
// child: Container(
// decoration: BoxDecoration(
// color: BackgroundColor,
// borderRadius: const BorderRadius.only(
// topLeft: Radius.circular(defaultRadius),
// bottomLeft: Radius.circular(defaultRadius),
// ),
// ),
// child: Center(
// child: AspectRatio(
// aspectRatio: 1,
// child: ClipRRect(
// borderRadius: BorderRadius.circular(defaultRadius),
// child: Container(
// color: BackgroundColor,
// child: const Icon(
// Icons.image,
// size: 32,
// color: iconColor,
// ),
// ),
// ),
// ),
// ),
// ),
// ),
// const SizedBox(width: 12),
// Expanded(
// child: Padding(
// padding: const EdgeInsets.symmetric(
// vertical: 10,
// horizontal: 8,
// ),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// mainAxisSize: MainAxisSize.min,
// children: [
// Text(
// title,
// maxLines: 2,
// overflow: TextOverflow.ellipsis,
// style: const TextStyle(
// fontSize: 16,
// fontWeight: FontWeight.w600,
// ),
// ),
// const SizedBox(height: 8),
// Row(children: [Expanded(child: Text(body))]),
// // Align(
// //   alignment: Alignment.centerRight,
// //   child: TradeStatusChip(
// //     label: status,
// //     color: CurrentTradeViewModel.getStatusColor(status),
// //   ),
// // ),
// Text(date?.toTimesAgo() as String),
// ],
// ),
// ),
// ),
// IconButton(onPressed: onDelete, icon: Icon(Icons.close)),
// ],
// ),
// if (!is_checked)
// Positioned(
// bottom: 8,
// right: 8,
// child: Container(
// width: 8,
// height: 8,
// decoration: const BoxDecoration(
// color: Color(0xFF3B82F6), // 파란색 (원하면 변경)
// shape: BoxShape.circle,
// ),
// ),
// ),
// ],
// ),
// )
