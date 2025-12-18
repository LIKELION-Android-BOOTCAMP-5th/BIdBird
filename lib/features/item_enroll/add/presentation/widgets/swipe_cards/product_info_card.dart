import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/category_bottom_sheet.dart';
import 'package:bidbird/core/widgets/item/components/sections/image_upload_section.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';
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
  String? _categoryError;
  bool _shouldShowErrors = false;

  void validateFields() {
    setState(() {
      _shouldShowErrors = true;
      _imageError = null;
      _titleError = null;
      _categoryError = null;

      if (widget.viewModel.selectedImages.isEmpty) {
        _imageError = '상품 이미지를 업로드해주세요';
      }

      if (widget.viewModel.titleController.text.trim().isEmpty) {
        _titleError = '제목을 입력해주세요';
      }

      if (widget.viewModel.selectedKeywordTypeId == null) {
        _categoryError = '카테고리를 선택해주세요';
      }
    });
  }

  void _clearErrors() {
    setState(() {
      _shouldShowErrors = false;
      _imageError = null;
      _titleError = null;
      _categoryError = null;
    });
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
          ImageUploadSection(
            images: widget.viewModel.selectedImages,
            maxImageCount: 10,
            primaryImageIndex: widget.viewModel.primaryImageIndex,
            onPrimaryImageTap: (index) => widget.viewModel.setPrimaryImage(index),
            supportVideo: true,
            onAddImage: widget.onImageSourceTap,
            onRemoveImage: (index) => widget.viewModel.removeImageAt(index),
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
                '최대 10장',
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
                  fillColor: Colors.white,
                  errorText: _shouldShowErrors ? _titleError : null,
                  errorMaxLines: 1,
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
          SizedBox(height: spacing),
          // 카테고리 선택
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                child: Row(
                  children: [
                    Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              widget.viewModel.isLoadingKeywords
                  ? Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.inputPadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(defaultRadius),
                        border: Border.all(
                          color: _shouldShowErrors && _categoryError != null
                              ? RedColor
                              : BackgroundColor,
                        ),
                      ),
                      child: SizedBox(
                        height: context.iconSizeSmall,
                        width: context.iconSizeSmall,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        CategoryBottomSheet.show(
                          context,
                          categories: widget.viewModel.keywordTypes,
                          selectedCategoryId: widget.viewModel.selectedKeywordTypeId,
                          onCategorySelected: (id) {
                            widget.viewModel.setSelectedKeywordTypeId(id);
                            // 카테고리 선택 시 에러 제거
                            if (_shouldShowErrors && _categoryError != null) {
                              setState(() {
                                _categoryError = null;
                              });
                            }
                          },
                        );
                      },
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.inputPadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(defaultRadius),
                          border: Border.all(
                            color: _shouldShowErrors && _categoryError != null
                                ? RedColor
                                : widget.viewModel.selectedKeywordTypeId != null
                                    ? blueColor
                                    : BackgroundColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.viewModel.selectedKeywordTypeId != null
                                      ? widget.viewModel.keywordTypes
                                          .firstWhere(
                                            (e) =>
                                                e.id ==
                                                widget.viewModel
                                                    .selectedKeywordTypeId,
                                            orElse: () =>
                                                widget.viewModel.keywordTypes.first,
                                          )
                                          .title
                                      : '카테고리 선택',
                                  style: TextStyle(
                                    fontSize: context.fontSizeSmall,
                                    color:
                                        widget.viewModel.selectedKeywordTypeId != null
                                            ? textColor
                                            : iconColor,
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: widget.viewModel.selectedKeywordTypeId != null
                                  ? blueColor
                                  : iconColor,
                            ),
                          ],
                        ),
                      ),
                    ),
              if (_shouldShowErrors && _categoryError != null)
                Padding(
                  padding: EdgeInsets.only(top: context.spacingSmall),
                  child: Text(
                    _categoryError!,
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      color: RedColor,
                    ),
                  ),
                ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}


