import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/features/chat/presentation/widgets/full_screen_image_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrlForMessage = message.thumbnailUrl ?? message.imageUrl;
    
    // 이미지 메시지인 경우 버블 없이 이미지만 표시
    if (message.messageType == "image" && imageUrlForMessage != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = MediaQuery.of(context).size.width * 0.72;
          final imageWidget = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: 600, // 세로로 긴 이미지를 위해 최대 높이 증가
            ),
            child: GestureDetector(
              onTap: () {
                // 원본 이미지 URL 사용 (thumbnailUrl이 있으면 imageUrl 사용)
                final originalImageUrl = message.imageUrl ?? imageUrlForMessage;
                FullScreenImageViewer.show(context, originalImageUrl);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrlForMessage,
                  cacheManager: ItemImageCacheManager.instance,
                  fit: BoxFit.contain, // 이미지 전체가 보이도록 변경
                  width: maxWidth,
                  placeholder: (context, url) => Container(
                    width: maxWidth,
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: maxWidth,
                    height: 200,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );

          // 시간 표시가 필요 없으면 이미지만 출력
          if (!showTime) {
            return Align(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: imageWidget,
              ),
            );
          }

          // 시간 표시
          final timeAndReadStyle = const TextStyle(
            color: chatTimeTextColor,
            fontSize: 11,
            height: 1.0,
          );
          
          final timeText = Text(
            _formatTime(message.createdAt),
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

          return Align(
            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: isCurrentUser
                    ? [
                        Flexible(
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                timeText,
                                if (readStatusIndicator != null) ...[
                                  const SizedBox(width: 4),
                                  readStatusIndicator,
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: imageWidget),
                      ]
                    : [
                        Flexible(child: imageWidget),
                        const SizedBox(width: 6),
                        Flexible(child: timeText),
                      ],
              ),
            ),
          );
        },
      );
    }

    // 텍스트 메시지인 경우 기존 버블 스타일 유지
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isCurrentUser ? myMessageBubbleColor : opponentMessageBubbleColor,
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
        message.text ?? "메세지",
        style: TextStyle(
          color: isCurrentUser ? Colors.white : chatTextColor,
          fontSize: 15,
        ),
      ),
    );

    // 시간 표시가 필요 없으면 버블만 출력
    if (!showTime) {
      return Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: bubble,
        ),
      );
    }

    // showTime == true 인 경우, 버블 옆(가운데 높이)에 시간 표시
    // 시간과 읽음이 정확히 같은 높이에 정렬되도록 같은 TextStyle 사용
    final timeAndReadStyle = const TextStyle(
      color: chatTimeTextColor,
      fontSize: 11,
      height: 1.0, // line height를 1.0으로 설정하여 정확한 정렬
    );
    
    final timeText = Text(
      _formatTime(message.createdAt),
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

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isCurrentUser
              ? [
                  // 시간과 읽음/안읽음을 같은 높이에 수평 정렬
                  // IntrinsicHeight를 사용하여 정확한 높이 정렬
                  Flexible(
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          timeText,
                          if (readStatusIndicator != null) ...[
                            const SizedBox(width: 4),
                            readStatusIndicator,
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: bubble),
                ]
              : [
                  Flexible(child: bubble),
                  const SizedBox(width: 6),
                  Flexible(child: timeText),
                ],
        ),
      ),
    );
  }
}
