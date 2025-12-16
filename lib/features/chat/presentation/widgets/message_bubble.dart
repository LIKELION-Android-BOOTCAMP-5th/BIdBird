import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/presentation/widgets/message_media_widget.dart';
import 'package:bidbird/features/chat/presentation/widgets/message_text_bubble.dart';
import 'package:bidbird/features/chat/presentation/widgets/message_time_and_read_status.dart';
import 'package:flutter/material.dart';

/// 메시지 버블 위젯
class MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isCurrentUser;
  final bool showTime;
  final bool isRead; // 읽음 여부
  final bool isUnread; // 안읽음 여부 (마지막 내 메시지가 읽지 않았을 때)

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showTime = true,
    this.isRead = false,
    this.isUnread = false,
  });


  @override
  Widget build(BuildContext context) {
    final String? imageUrlForMessage = message.thumbnailUrl ?? message.imageUrl;
    
    // 이미지 메시지인 경우
    if (message.messageType == "image" && imageUrlForMessage != null) {
      return _buildMediaMessage(context);
    }

    // 텍스트 메시지인 경우
    return _buildTextMessage(context);
  }

  /// 미디어 메시지 빌드 (이미지/비디오)
  Widget _buildMediaMessage(BuildContext context) {
    final maxWidth = _getMaxMessageWidth(context);
    
    final mediaWidget = MessageMediaWidget(
      message: message,
      maxWidth: maxWidth,
      maxHeight: 600,
    );

    // 시간 표시가 필요 없으면 미디어만 출력
    if (!showTime) {
      return Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isCurrentUser ? 12 : 0,
            right: isCurrentUser ? 12 : 0,
          ),
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: mediaWidget,
        ),
      );
    }

    // 시간 및 읽음 상태 표시
    final timeAndReadStatus = MessageTimeAndReadStatus(
      message: message,
      isCurrentUser: isCurrentUser,
      isRead: isRead,
      isUnread: isUnread,
    );

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? 12 : 0,
          right: isCurrentUser ? 12 : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isCurrentUser
              ? [
                  timeAndReadStatus,
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: mediaWidget,
                  ),
                ]
              : [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: mediaWidget,
                  ),
                  const SizedBox(width: 6),
                  timeAndReadStatus,
                ],
        ),
      ),
    );
  }

  /// 텍스트 메시지 빌드
  Widget _buildTextMessage(BuildContext context) {
    final bubble = MessageTextBubble(
      message: message,
      isCurrentUser: isCurrentUser,
    );

    // 시간 표시가 필요 없으면 버블만 출력
    if (!showTime) {
      return Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isCurrentUser ? 12 : 0,
            right: isCurrentUser ? 12 : 0,
          ),
          constraints: BoxConstraints(
            maxWidth: _getMaxMessageWidth(context),
          ),
          child: bubble,
        ),
      );
    }

    // 시간 및 읽음 상태 표시
    final timeAndReadStatus = MessageTimeAndReadStatus(
      message: message,
      isCurrentUser: isCurrentUser,
      isRead: isRead,
      isUnread: isUnread,
    );

    final maxWidth = _getMaxMessageWidth(context);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? 12 : 0,
          right: isCurrentUser ? 12 : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isCurrentUser
              ? [
                  timeAndReadStatus,
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: bubble,
                  ),
                ]
              : [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: bubble,
                  ),
                  const SizedBox(width: 6),
                  timeAndReadStatus,
                ],
        ),
      ),
    );
  }

  /// 메시지 최대 너비 계산 (시간 표시 여부와 관계없이 동일)
  /// 화면의 70% 활용
  double _getMaxMessageWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.70;
  }
}
