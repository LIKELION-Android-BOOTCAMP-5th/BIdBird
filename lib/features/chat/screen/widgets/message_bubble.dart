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

          if (message.message_type == "image")
            LayoutBuilder(
              builder: (context, constraints) {
                return FutureBuilder<Size>(
                  future: _getImageSize(message.image_url!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        width: constraints.maxWidth,
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final imageSize = snapshot.data!;
                    final aspectRatio = imageSize.width / imageSize.height;

                    return AspectRatio(
                      aspectRatio: aspectRatio,
                      child: CachedNetworkImage(
                        imageUrl: message.image_url!,
                        cacheManager: ItemImageCacheManager.instance,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              bubble,
              if (showTime) ...[
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.created_at),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 원본 이미지 width/height 읽어오기
  Future<Size> _getImageSize(String url) async {
    final completer = Completer<Size>();
    final img = Image.network(url);

    img.image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            final myImage = info.image;
            completer.complete(
              Size(myImage.width.toDouble(), myImage.height.toDouble()),
            );
          }),
        );

    return completer.future;
  }
}
