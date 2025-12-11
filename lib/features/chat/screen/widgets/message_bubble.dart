import 'dart:async';

import 'package:bidbird/core/utils/extension/time_extension.dart';
import 'package:bidbird/features/chat/model/chat_message_entity.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 메시지 버블 위젯
class MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.message_type == "text")
              Text(
                message.text ?? "메세지",
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                  fontSize: 16,
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
            const SizedBox(height: 4),
            Text(message.created_at.toTimesAgo()),
            // Text(
            //   DateFormat('HH:mm').format("message.createdAt" as DateTime),
            //   style: TextStyle(
            //     color: isCurrentUser ? Colors.white70 : Colors.black54,
            //     fontSize: 12,
            //   ),
            // ),
          ],
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
