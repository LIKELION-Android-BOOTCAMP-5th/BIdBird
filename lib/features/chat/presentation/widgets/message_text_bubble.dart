import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:flutter/material.dart';

/// 텍스트 메시지 버블 위젯
class MessageTextBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isCurrentUser;

  const MessageTextBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? myMessageBubbleColor
            : opponentMessageBubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isCurrentUser ? 16 : 4),
          topRight: Radius.circular(isCurrentUser ? 4 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
        boxShadow: isCurrentUser
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text ?? '메시지',
        style: TextStyle(
          color: isCurrentUser ? Colors.white : chatTextColor,
          fontSize: 15,
        ),
      ),
    );
  }
}



