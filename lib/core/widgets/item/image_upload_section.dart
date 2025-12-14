import 'dart:io';

import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/video_player_widget.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 재사용 가능한 이미지 업로드 섹션 컴포넌트
/// 신고하기와 매물 등록에서 공통으로 사용
class ImageUploadSection extends StatelessWidget {
  const ImageUploadSection({
    super.key,
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
    this.maxImageCount = 5,
    this.primaryImageIndex,
    this.onPrimaryImageTap,
    this.supportVideo = false,
  });

  /// 선택된 이미지 리스트
  final List<XFile> images;

  /// 이미지 추가 버튼 클릭 시 콜백
  final VoidCallback onAddImage;

  /// 이미지 삭제 콜백 (index 전달)
  final Function(int index) onRemoveImage;

  /// 최대 이미지 개수
  final int maxImageCount;

  /// 대표 이미지 인덱스 (null이면 대표 이미지 표시 안 함)
  final int? primaryImageIndex;

  /// 대표 이미지 선택 콜백 (null이면 대표 이미지 선택 불가)
  final Function(int index)? onPrimaryImageTap;

  /// 비디오 지원 여부
  final bool supportVideo;

  @override
  Widget build(BuildContext context) {
    const Color backgroundGray = Color(0xFFF7F8FA);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textSecondary = Color(0xFF6B7280);
    const Color buttonDisabledBg = Color(0xFFE5E7EB);

    return Container(
      height: context.heightRatio(0.2, min: 140.0, max: 200.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: defaultBorder,
        border: Border.all(
          color: borderGray,
        ),
      ),
      child: Stack(
        children: [
          // 이미지가 없을 때: 중앙에 업로드 아이콘과 텍스트
          if (images.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    color: textSecondary,
                    size: context.iconSizeSmall * 1.3,
                  ),
                  SizedBox(height: context.spacingSmall),
                  Text(
                    '이미지를 업로드하세요',
                    style: TextStyle(
                      fontSize: context.widthRatio(0.03, min: 10.0, max: 14.0),
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            )
          // 이미지가 있을 때: 가로 스크롤 리스트
          else
            ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: context.inputPadding,
                vertical: context.inputPadding,
              ),
              itemBuilder: (context, index) {
                final image = images[index];
                final bool isPrimary = primaryImageIndex != null && 
                                      primaryImageIndex == index;
                final bool isVideo = supportVideo && isVideoFile(image.path);

                return GestureDetector(
                  onTap: onPrimaryImageTap != null
                      ? () => onPrimaryImageTap!(index)
                      : null,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: defaultBorder,
                          border: Border.all(
                            color: borderGray,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: defaultBorder,
                          child: isVideo
                              ? SizedBox(
                                  width: context.imageSize,
                                  height: context.imageSize,
                                  child: VideoPlayerWidget(
                                    videoPath: image.path,
                                    autoPlay: false,
                                    showControls: true,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.file(
                                  File(image.path),
                                  width: context.imageSize,
                                  height: context.imageSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: context.imageSize,
                                      height: context.imageSize,
                                      color: backgroundGray,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: textSecondary,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      // 삭제 버튼
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: textSecondary.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      // 대표 이미지 라벨
                      if (isPrimary)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.inputPadding * 0.67,
                                vertical: context.spacingSmall * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: blueColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '대표 이미지',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.widthRatio(
                                    0.028,
                                    min: 9.0,
                                    max: 13.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => SizedBox(width: context.spacingSmall),
              itemCount: images.length,
            ),
          // 왼쪽 하단: 이미지 개수 표시 버튼
          Positioned(
            left: context.inputPadding * 0.67,
            bottom: context.inputPadding * 0.67,
            child: Container(
              width: context.iconSizeMedium,
              height: context.iconSizeMedium,
              decoration: BoxDecoration(
                color: blueColor,
                borderRadius: defaultBorder,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${images.length}/$maxImageCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.widthRatio(0.03, min: 10.0, max: 14.0),
                  ),
                ),
              ),
            ),
          ),
          // 오른쪽 하단: 이미지 추가 버튼
          Positioned(
            right: context.inputPadding * 0.67,
            bottom: context.inputPadding * 0.67,
            child: GestureDetector(
              onTap: images.length < maxImageCount ? onAddImage : null,
              child: Container(
                width: context.iconSizeMedium,
                height: context.iconSizeMedium,
                decoration: BoxDecoration(
                  color: images.length < maxImageCount
                      ? blueColor
                      : buttonDisabledBg,
                  borderRadius: defaultBorder,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: context.iconSizeSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
