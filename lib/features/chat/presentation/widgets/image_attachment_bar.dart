import 'dart:io';

import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/widgets/video_player_widget.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:flutter/material.dart';

/// 이미지 첨부 바 위젯
/// 여러 이미지를 가로 스크롤로 표시하고 각각 삭제 가능
class ImageAttachmentBar extends StatelessWidget {
  final ChattingRoomViewmodel viewModel;

  const ImageAttachmentBar({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FA), // 이미지 첨부 바 배경
          border: Border(
            top: BorderSide(
              color: Color(0xFFE1E4E8), // 상단 divider
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: SizedBox(
          height: 64, // 썸네일 + 여유 공간
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.images.length,
            itemBuilder: (context, index) {
              final image = viewModel.images[index];
              final isVideo = isVideoFile(image.path);

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    // 이미지 썸네일 (48x48)
                    GestureDetector(
                      onTap: () {
                        // 전체 미리보기 열기 (추후 구현 가능)
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE1E4E8),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isVideo
                              ? SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: VideoPlayerWidget(
                                    videoPath: image.path,
                                    autoPlay: false,
                                    showControls: false,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.file(
                                  File(image.path),
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    // 제거 버튼 (X) - 우상단 오버레이 (가려지지 않도록 개선)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () {
                          viewModel.clearImage(index);
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFE1E4E8),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF5F6368),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

