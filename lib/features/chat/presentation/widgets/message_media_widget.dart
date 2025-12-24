import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/widgets/item/dialogs/full_screen_image_gallery_viewer.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/core/widgets/full_screen_video_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 메시지 미디어 위젯 (이미지/비디오)
class MessageMediaWidget extends StatelessWidget {
  final ChatMessageEntity message;
  final double maxWidth;
  final double maxHeight;
  final List<ChatMessageEntity>? allMessages; // 모든 메시지 리스트 (갤러리용)

  const MessageMediaWidget({
    super.key,
    required this.message,
    required this.maxWidth,
    this.maxHeight = 600,
    this.allMessages,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrlForMessage = message.thumbnailUrl ?? message.imageUrl;
    final String? originalUrl = message.imageUrl ?? imageUrlForMessage;

    if (imageUrlForMessage == null) {
      return const SizedBox.shrink();
    }

    // 동영상 URL인지 확인
    final bool isVideo = originalUrl != null && isVideoFile(originalUrl);

    if (isVideo && originalUrl != null) {
      return _buildVideoWidget(context, originalUrl, imageUrlForMessage);
    } else {
      return _buildImageWidget(context, imageUrlForMessage);
    }
  }

  /// 비디오 위젯 빌드
  Widget _buildVideoWidget(
    BuildContext context,
    String originalUrl,
    String thumbnailUrl,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: GestureDetector(
        onTap: () {
          FullScreenVideoViewer.show(context, originalUrl);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 썸네일 이미지 (동영상의 첫 프레임)
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                cacheManager: ItemImageCacheManager.instance,
                fit: BoxFit.contain,
                width: maxWidth,
                // 메모리 최적화
                memCacheWidth: (maxWidth * MediaQuery.of(context).devicePixelRatio).round(),
                memCacheHeight: (maxHeight * MediaQuery.of(context).devicePixelRatio).round(),
                placeholder: (context, url) => Container(
                  width: maxWidth,
                  height: 200,
                  color: Colors.black87,
                ),
                errorWidget: (context, url, error) => Container(
                  width: maxWidth,
                  height: 200,
                  color: Colors.black87,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.videocam_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              // 재생 아이콘 오버레이
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이미지 위젯 빌드
  Widget _buildImageWidget(BuildContext context, String imageUrl) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: GestureDetector(
        onTap: () {
          final originalImageUrl = message.imageUrl ?? imageUrl;
          
          // 모든 메시지가 제공된 경우 갤러리 뷰어 사용
          if (allMessages != null) {
            final imageUrls = _extractImageUrls(allMessages!);
            if (imageUrls.isNotEmpty) {
              final initialIndex = imageUrls.indexOf(originalImageUrl);
              FullScreenImageGalleryViewer.show(
                context,
                imageUrls,
                initialIndex: initialIndex >= 0 ? initialIndex : 0,
              );
              return;
            }
          }
          
          // 단일 이미지 뷰어 사용 (fallback)
          FullScreenImageGalleryViewer.show(
            context,
            [originalImageUrl],
            initialIndex: 0,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            cacheManager: ItemImageCacheManager.instance,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              width: maxWidth,
              height: 200,
              color: Colors.grey[200],
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
  }

  /// 메시지 리스트에서 이미지 URL 추출 (비디오 제외)
  List<String> _extractImageUrls(List<ChatMessageEntity> messages) {
    final imageUrls = <String>[];
    for (final msg in messages) {
      if (msg.messageType == 'image' && msg.imageUrl != null) {
        final url = msg.imageUrl!;
        // 비디오가 아닌 경우만 추가
        if (!isVideoFile(url)) {
          imageUrls.add(url);
        }
      }
    }
    return imageUrls;
  }
}



