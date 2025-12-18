import 'dart:io';

import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:bidbird/core/widgets/video_player_widget.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
/// 카드 1: 상품 정보
class ProductInfoCard extends StatefulWidget {
  const ProductInfoCard({
    super.key,
    required this.viewModel,
    required this.onImageSourceTap,
    required this.inputDecoration,
  });

  final ItemAddViewModel viewModel;
  final VoidCallback onImageSourceTap;
  final InputDecoration Function(String hint) inputDecoration;

  @override
  State<ProductInfoCard> createState() => ProductInfoCardState();
}

class ProductInfoCardState extends State<ProductInfoCard> {
  String? _imageError;
  String? _titleError;
  bool _shouldShowErrors = false;
  final PageController _imagePageController = PageController();

  void validateFields() {
    setState(() {
      _shouldShowErrors = true;
      _imageError = null;
      _titleError = null;

      if (widget.viewModel.selectedImages.isEmpty) {
        _imageError = '상품 이미지를 업로드해주세요';
      }

      if (widget.viewModel.titleController.text.trim().isEmpty) {
        _titleError = '제목을 입력해주세요';
      }
    });
  }

  void _clearErrors() {
    setState(() {
      _shouldShowErrors = false;
      _imageError = null;
      _titleError = null;
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Widget _buildSingleImage(
    BuildContext context,
    XFile image,
    bool isPrimary,
    int index,
  ) {
    final bool isVideo = isVideoFile(image.path);
    
    return GestureDetector(
      onTap: () => widget.viewModel.setPrimaryImage(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: defaultBorder,
            child: isVideo
                ? VideoPlayerWidget(
                    videoPath: image.path,
                    autoPlay: false,
                    showControls: true,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(image.path),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
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
            top: context.inputPadding * 0.67,
            right: context.inputPadding * 0.67,
            child: GestureDetector(
              onTap: () => widget.viewModel.removeImageAt(index),
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
              bottom: context.inputPadding * 0.67,
              left: 0,
              right: 0,
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.fontSizeSmall * 0.85,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacingMedium;
    final labelFontSize = context.fontSizeMedium;

    // 이미지가 업로드되면 에러 제거
    if (_shouldShowErrors && _imageError != null && widget.viewModel.selectedImages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _imageError = null;
          });
        }
      });
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.hPadding,
        vertical: context.vPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 업로드 섹션
          Padding(
            padding: EdgeInsets.only(bottom: context.labelBottomPadding),
            child: Row(
              children: [
                Text(
                  '상품 이미지',
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          // 정사각형 이미지 업로드 섹션
          LayoutBuilder(
            builder: (context, constraints) {
              // 제목 입력 필드와 동일한 너비 사용
              final availableWidth = constraints.maxWidth;
              
              return SizedBox(
                width: availableWidth,
                height: availableWidth, // 정사각형
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: defaultBorder,
                    border: Border.all(
                      color: const Color(0xFFE6E8EB),
                    ),
                  ),
                  child: Stack(
                  children: [
                    // 이미지가 없을 때: 중앙에 업로드 아이콘과 텍스트
                    if (widget.viewModel.selectedImages.isEmpty)
                      Center(
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
                      )
                    // 이미지가 있을 때
                    else
                      widget.viewModel.selectedImages.length == 1
                          ? // 이미지가 1개일 때: 전체 영역을 꽉 채움
                          _buildSingleImage(
                            context,
                            widget.viewModel.selectedImages[0],
                            widget.viewModel.primaryImageIndex == 0,
                            0,
                          )
                          : // 이미지가 여러 개일 때: 스와이프로 볼 수 있게
                          PageView.builder(
                            controller: _imagePageController,
                            itemCount: widget.viewModel.selectedImages.length,
                            itemBuilder: (context, index) {
                              final image = widget.viewModel.selectedImages[index];
                              final bool isPrimary = widget.viewModel.primaryImageIndex != null && 
                                                    widget.viewModel.primaryImageIndex == index;
                              
                              return _buildSingleImage(
                                context,
                                image,
                                isPrimary,
                                index,
                              );
                            },
                          ),
                    // 왼쪽 하단: 이미지 개수 표시
                    Positioned(
                      left: context.inputPadding * 0.67,
                      bottom: context.inputPadding * 0.67,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.inputPadding * 0.67,
                          vertical: context.spacingSmall * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: blueColor,
                          borderRadius: defaultBorder,
                        ),
                        child: Text(
                          '${widget.viewModel.selectedImages.length}/10',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.fontSizeSmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // 오른쪽 하단: 이미지 추가 버튼
                    Positioned(
                      right: context.inputPadding * 0.67,
                      bottom: context.inputPadding * 0.67,
                      child: GestureDetector(
                        onTap: widget.viewModel.selectedImages.length < 10
                            ? widget.onImageSourceTap
                            : null,
                        child: Container(
                          width: context.iconSizeMedium,
                          height: context.iconSizeMedium,
                          decoration: BoxDecoration(
                            color: widget.viewModel.selectedImages.length < 10
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
          ),
          if (_shouldShowErrors && _imageError != null)
            Padding(
              padding: EdgeInsets.only(top: context.spacingSmall),
              child: Text(
                _imageError!,
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: RedColor,
                ),
              ),
            ),
          // 안내 문구
          Padding(
            padding: EdgeInsets.only(
              top: context.spacingSmall,
              bottom: spacing,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '최소 1장 최대 10장',
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: iconColor,
                ),
              ),
            ),
          ),
          SizedBox(height: spacing),
          // 제목 입력
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                child: Row(
                  children: [
                    Text(
                      '제목',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: widget.viewModel.titleController,
                decoration: widget.inputDecoration('상품 제목을 입력하세요').copyWith(
                  errorText: _shouldShowErrors ? _titleError : null,
                ),
                onChanged: (value) {
                  // 입력 시 에러가 있으면 제거
                  if (_shouldShowErrors && _titleError != null && value.trim().isNotEmpty) {
                    setState(() {
                      _titleError = null;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}


