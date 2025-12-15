import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/features/chat/presentation/widgets/full_screen_image_viewer.dart';
import 'package:bidbird/features/chat/presentation/widgets/full_screen_video_viewer.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final String? originalUrl = message.imageUrl ?? imageUrlForMessage;
    
    // 이미지 메시지인 경우 버블 없이 이미지만 표시
    if (message.messageType == "image" && imageUrlForMessage != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // 이미지 표시 크기 축소: 화면의 60%로 제한, 최대 높이 400px
          final maxWidth = MediaQuery.of(context).size.width * 0.60;
          
          // 동영상 URL인지 확인
          final bool isVideo = originalUrl != null && isVideoFile(originalUrl);
          
          final Widget mediaWidget;
          
          if (isVideo) {
            // 동영상인 경우 썸네일 이미지처럼 표시하고, 탭하면 전체 화면으로 재생
            final thumbnailUrl = getVideoThumbnailUrl(originalUrl!);
            mediaWidget = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: 400,
              ),
              child: GestureDetector(
                onTap: () {
                  // 전체 화면 비디오 플레이어로 재생
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
          } else {
            // 이미지인 경우 - 긴 사진 정렬 개선
            mediaWidget = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: 600, // 최대 높이 증가 (400 -> 600)
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
                    fit: BoxFit.contain, // 비율 유지하면서 표시
                    width: null, // width 제거하여 비율에 맞게 자동 조정
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

          // 시간 표시가 필요 없으면 미디어만 출력
          if (!showTime) {
            return Align(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(
                  left: isCurrentUser ? 12 : 0,
                  right: isCurrentUser ? 12 : 0, // 텍스트 버블과 동일한 마진
                ),
                child: mediaWidget,
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

          return Align(
            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(
                left: isCurrentUser ? 12 : 0,
                right: isCurrentUser ? 12 : 0, // 텍스트 버블과 동일한 마진
              ),
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
                        Flexible(child: mediaWidget),
                      ]
                    : [
                        Flexible(child: mediaWidget),
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
        (message.text ?? "메세지").replaceAll(RegExp(r'\s*\(?\s*낙찰자\s*\)?\s*'), ''),
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
          margin: EdgeInsets.only(
            left: isCurrentUser ? 12 : 0,
            right: isCurrentUser ? 12 : 0,
          ),
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

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? 12 : 0,
          right: isCurrentUser ? 12 : 0,
        ),
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
