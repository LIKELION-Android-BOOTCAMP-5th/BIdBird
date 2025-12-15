import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:flutter/material.dart';

/// 메시지 시간 및 읽음 상태 위젯
class MessageTimeAndReadStatus extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isCurrentUser;
  final bool isRead;
  final bool isUnread;

  const MessageTimeAndReadStatus({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isRead = false,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeAndReadStyle = const TextStyle(
      color: chatTimeTextColor,
      fontSize: 11,
      height: 1.0,
    );

    final timeText = Text(
      formatTimeFromIso(message.createdAt),
      style: timeAndReadStyle,
    );

    // 읽음/안읽음 표시 (내가 보낸 메시지에만 표시)
    Widget? readStatusIndicator;
    if (isCurrentUser) {
      if (isRead) {
        readStatusIndicator = Text(
          '읽음',
          style: timeAndReadStyle,
        );
      } else if (isUnread) {
        readStatusIndicator = Text(
          '안읽음',
          style: timeAndReadStyle,
        );
      }
    }

    if (readStatusIndicator == null) {
      return timeText;
    }

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          timeText,
          const SizedBox(width: 4),
          readStatusIndicator,
        ],
      ),
    );
  }
}



