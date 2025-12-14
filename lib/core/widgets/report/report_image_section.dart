import 'dart:io';

import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/features/report/viewmodel/report_viewmodel.dart';
import 'package:flutter/material.dart';

class ReportImageSection extends StatelessWidget {
  const ReportImageSection({
    super.key,
    required this.viewModel,
  });

  final ReportViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    const Color backgroundGray = Color(0xFFF7F8FA);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textSecondary = Color(0xFF6B7280);
    const Color buttonDisabledBg = Color(0xFFE5E7EB);

    final vm = viewModel;

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
          if (vm.selectedImages.isEmpty)
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
                final image = vm.selectedImages[index];
                return GestureDetector(
                  onTap: () => vm.removeImageAt(index),
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
                          child: Image.file(
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
                          onTap: () => vm.removeImageAt(index),
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
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => SizedBox(width: context.spacingSmall),
              itemCount: vm.selectedImages.length,
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
                  '${vm.selectedImages.length}/5',
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
              onTap: vm.selectedImages.length < 5
                  ? () {
                      ImageSourceBottomSheet.show(
                        context,
                        onGalleryTap: () => vm.pickImagesFromGallery(),
                        onCameraTap: () => vm.pickImageFromCamera(),
                      );
                    }
                  : null,
              child: Container(
                width: context.iconSizeMedium,
                height: context.iconSizeMedium,
                decoration: BoxDecoration(
                  color: vm.selectedImages.length < 5
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

