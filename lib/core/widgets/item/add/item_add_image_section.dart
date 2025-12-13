import 'dart:io';

import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/video_player_widget.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/features/item/add/viewmodel/item_add_viewmodel.dart';

class ItemAddImagesSection extends StatelessWidget {
  const ItemAddImagesSection({
    super.key,
    required this.viewModel,
    required this.onTapAdd,
  });

  final ItemAddViewModel viewModel;
  final VoidCallback onTapAdd;

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final containerHeight = context.heightRatio(0.2, min: 140.0, max: 200.0); // 특수 케이스: 이미지 컨테이너 높이
    final imageSize = context.imageSize;
    final buttonSize = context.iconSizeMedium;
    final iconSize = context.iconSizeSmall;
    final padding = context.inputPadding;
    final spacing = context.spacingSmall;
    final fontSize = context.widthRatio(0.03, min: 10.0, max: 14.0); // 특수 케이스: 이미지 카운트 폰트
    final labelFontSize = context.widthRatio(0.028, min: 9.0, max: 13.0); // 특수 케이스: 대표 이미지 라벨
    
    return Container(
      height: containerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: BackgroundColor,
        borderRadius: defaultBorder,
        border: Border.all(color: BackgroundColor),
      ),
      child: Stack(
        children: [
          if (viewModel.selectedImages.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    color: iconColor,
                    size: iconSize * 1.3,
                  ),
                  SizedBox(height: spacing),
                  Text(
                    '이미지를 업로드하세요',
                    style: TextStyle(fontSize: fontSize, color: iconColor),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding,
              ),
              itemBuilder: (context, index) {
                final image = viewModel.selectedImages[index];
                final bool isPrimary = index == viewModel.primaryImageIndex;
                return GestureDetector(
                  onTap: () {
                    viewModel.setPrimaryImage(index);
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: defaultBorder,
                        child: isVideoFile(image.path)
                            ? SizedBox(
                                width: imageSize,
                                height: imageSize,
                                child: VideoPlayerWidget(
                                  videoPath: image.path,
                                  autoPlay: false,
                                  showControls: true,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.file(
                                File(image.path),
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: imageSize,
                                    height: imageSize,
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.grey,
                                        size: iconSize,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Positioned(
                        top: spacing * 0.5,
                        right: spacing * 0.5,
                        child: GestureDetector(
                          onTap: () {
                            viewModel.removeImageAt(index);
                          },
                          child: Container(
                            width: buttonSize * 0.625,
                            height: buttonSize * 0.625,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(buttonSize * 0.3125),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close,
                              size: iconSize * 0.7,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isPrimary)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding * 0.67,
                                vertical: spacing * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: blueColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '대표 이미지',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: labelFontSize,
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
              separatorBuilder: (_, __) => SizedBox(width: spacing),
              itemCount: viewModel.selectedImages.length,
            ),
          Positioned(
            right: padding * 0.67,
            bottom: padding * 0.67,
            child: GestureDetector(
              onTap: onTapAdd,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: blueColor,
                  borderRadius: BorderRadius.circular(defaultRadius),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
          Positioned(
            left: padding * 0.67,
            bottom: padding * 0.67,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: blueColor,
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${viewModel.selectedImages.length}/10',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
