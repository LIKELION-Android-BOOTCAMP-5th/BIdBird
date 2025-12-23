import 'dart:io';

import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/spacing_ratios.dart';
import 'package:bidbird/core/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 정사각형 이미지 업로드 섹션
/// 매물 등록 화면에서 사용하는 정사각형 이미지 업로드 UI
class SquareImageUploadSection extends StatefulWidget {
  const SquareImageUploadSection({
    super.key,
    required this.images,
    required this.onImageSourceTap,
    required this.onImageTap,
    required this.onRemoveImage,
    required this.primaryImageIndex,
    this.width,
  });

  final List<XFile> images;
  final VoidCallback onImageSourceTap;
  final Function(int index) onImageTap;
  final Function(int index) onRemoveImage;
  final int? primaryImageIndex;
  final double? width;

  @override
  State<SquareImageUploadSection> createState() => _SquareImageUploadSectionState();
}

class _SquareImageUploadSectionState extends State<SquareImageUploadSection> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSingleImage(
    BuildContext context,
    XFile image,
    bool isPrimary,
    int index,
    double targetLogicalSize,
  ) {
    final bool isVideo = isVideoFile(image.path);
    // 기기 해상도에 맞춘 디코딩 크기 제한
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final int targetPx = (targetLogicalSize * dpr).round();

    return GestureDetector(
      onTap: () => widget.onImageTap(index),
      child: RepaintBoundary(
        child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: defaultBorder,
            child: isVideo
                ? VideoPlayerWidget(
                    key: ValueKey('video_${image.path}'),
                    videoPath: image.path,
                    autoPlay: false,
                    showControls: true,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(image.path),
                    key: ValueKey('img_${image.path}'),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: targetPx,
                    cacheHeight: targetPx,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: BackgroundColor,
                        child: Icon(
                          Icons.broken_image,
                          color: iconColor,
                        ),
                      );
                    },
                  ),
          ),
          // 삭제 버튼
          Positioned(
            top: context.inputPadding * SpacingRatios.imageOverlayPadding,
            right: context.inputPadding * SpacingRatios.imageOverlayPadding,
            child: GestureDetector(
              onTap: () => widget.onRemoveImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.8),
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
            Positioned(
              bottom: context.inputPadding * SpacingRatios.imageOverlayPadding,
              left: 0,
              right: 0,
              child: Center(
                child: IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: context.iconSizeMedium,
                      minHeight: context.iconSizeMedium,
                    ),
                    child: Container(
                      height: context.iconSizeMedium,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.inputPadding * SpacingRatios.imageOverlayPadding,
                      ),
                      decoration: BoxDecoration(
                        color: blueColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '대표 이미지',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.fontSizeSmall * SpacingRatios.smallFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.file_upload_outlined,
            color: iconColor,
            size: context.iconSizeMedium,
          ),
          SizedBox(height: context.spacingSmall),
          Text(
            '이미지를 업로드하세요',
            style: TextStyle(
              fontSize: context.fontSizeSmall,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = widget.width ?? constraints.maxWidth;
        final canAddMore = widget.images.length < ItemImageLimits.maxImageCount;
        
        return SizedBox(
          width: availableWidth,
          height: availableWidth, // 정사각형
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: defaultBorder,
              border: Border.all(
                color: LightBorderColor,
              ),
            ),
            child: Stack(
              children: [
                // 이미지가 없을 때: 중앙에 업로드 아이콘과 텍스트
                if (widget.images.isEmpty)
                  _buildEmptyState(context)
                // 이미지가 있을 때
                else
                  widget.images.length == 1
                      ? // 이미지가 1개일 때: 전체 영역을 꽉 채움
                      _buildSingleImage(
                        context,
                        widget.images[0],
                        widget.primaryImageIndex == 0,
                        0,
                        availableWidth,
                      )
                      : // 이미지가 여러 개일 때: 스와이프로 볼 수 있게
                      PageView.builder(
                        key: const PageStorageKey('square_image_upload_pageview'),
                        controller: _pageController,
                        itemCount: widget.images.length,
                        physics: const PageScrollPhysics(),
                        itemBuilder: (context, index) {
                          final image = widget.images[index];
                          final bool isPrimary = widget.primaryImageIndex != null && 
                                                widget.primaryImageIndex == index;
                          
                          return KeyedSubtree(
                            key: ValueKey('page_${image.path}'),
                            child: _buildSingleImage(
                              context,
                              image,
                              isPrimary,
                              index,
                              availableWidth,
                            ),
                          );
                        },
                      ),
                // 왼쪽 하단: 이미지 개수 표시
                Positioned(
                  left: context.inputPadding * SpacingRatios.imageOverlayPadding,
                  bottom: context.inputPadding * SpacingRatios.imageOverlayPadding,
                  child: IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: context.iconSizeMedium,
                        minHeight: context.iconSizeMedium,
                      ),
                      child: Container(
                        height: context.iconSizeMedium,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.inputPadding * SpacingRatios.imageOverlayPadding,
                        ),
                        decoration: BoxDecoration(
                          color: blueColor,
                          borderRadius: defaultBorder,
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${widget.images.length}/${ItemImageLimits.maxImageCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 오른쪽 하단: 이미지 추가 버튼
                Positioned(
                  right: context.inputPadding * SpacingRatios.imageOverlayPadding,
                  bottom: context.inputPadding * SpacingRatios.imageOverlayPadding,
                  child: GestureDetector(
                    onTap: canAddMore ? widget.onImageSourceTap : null,
                    child: Container(
                      width: context.iconSizeMedium,
                      height: context.iconSizeMedium,
                      decoration: BoxDecoration(
                        color: canAddMore
                            ? blueColor
                            : BorderColor.withValues(alpha: 0.3),
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
          ),
        );
      },
    );
  }
}



