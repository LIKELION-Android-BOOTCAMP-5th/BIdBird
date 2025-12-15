import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/presentation/widgets/full_screen_image_viewer.dart';
import 'package:bidbird/features/chat/presentation/widgets/full_screen_video_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 메시지 미디어 위젯 (이미지/비디오)
class MessageMediaWidget extends StatelessWidget {
  final ChatMessageEntity message;
  final double maxWidth;
  final double maxHeight;

  const MessageMediaWidget({
    super.key,
    required this.message,
    required this.maxWidth,
    this.maxHeight = 600,
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

    if (isVideo) {
      return _buildVideoWidget(context, originalUrl!, imageUrlForMessage);
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
                placeholder: (context, url) => Container(
                  width: maxWidth,
                  height: 200,
                  color: Colors.black87,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
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
          FullScreenImageViewer.show(context, originalImageUrl);
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
  }
}



