import 'dart:async';

import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/chat/model/chat_message_entity.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 메시지 버블 위젯
class MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isCurrentUser;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showTime = true,
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
    final String? imageUrlForMessage = message.thumbnail_url ?? message.image_url;
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isCurrentUser ? blueColor : Colors.white,
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
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.message_type == "text")
            Text(
              message.text ?? "메세지",
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),

          if (message.message_type == "image" && imageUrlForMessage != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                    // 너무 큰 이미지는 줄이고, 세로는 적당한 최대 높이 제한
                    maxHeight: 280,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: imageUrlForMessage,
                      cacheManager: ItemImageCacheManager.instance,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
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
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
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
    final timeText = Text(
      _formatTime(message.created_at),
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 11,
      ),
    );

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isCurrentUser
              ? [
                  timeText,
                  const SizedBox(width: 6),
                  Flexible(child: bubble),
                ]
              : [
                  Flexible(child: bubble),
                  const SizedBox(width: 6),
                  timeText,
                ],
        ),
      ),
    );
  }
}
