import 'package:bidbird/core/mixins/form_validation_mixin.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/input_decoration_style.dart';
import 'package:bidbird/core/widgets/item/components/fields/error_text.dart';
import 'package:bidbird/core/widgets/item/components/fields/form_label.dart';
import 'package:bidbird/core/widgets/item/components/sections/square_image_upload_section.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_error_messages.dart';
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

class ProductInfoCardState extends State<ProductInfoCard> with FormValidationMixin {
  String? _imageError;
  String? _titleError;
  bool _shouldShowErrors = false;

  @override
  bool get shouldShowErrors => _shouldShowErrors;

  @override
  set shouldShowErrors(bool value) => _shouldShowErrors = value;

  void validateFields() {
    startValidation(() {
      if (widget.viewModel.selectedImages.isEmpty) {
        _imageError = ItemRegistrationErrorMessages.imageMinRequired;
      }

      if (widget.viewModel.titleController.text.trim().isEmpty) {
        _titleError = ItemRegistrationErrorMessages.titleRequired;
      }
    });
  }

  @override
  void clearAllErrors() {
    _imageError = null;
    _titleError = null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacingMedium;

    // 이미지가 업로드되면 에러 제거
    if (shouldShowErrors && _imageError != null && widget.viewModel.selectedImages.isNotEmpty) {
      clearError(() => _imageError = null);
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
          FormLabel(text: '상품 이미지'),
          SquareImageUploadSection(
            images: widget.viewModel.selectedImages,
            onImageSourceTap: widget.onImageSourceTap,
            onImageTap: (index) => widget.viewModel.setPrimaryImage(index),
            onRemoveImage: (index) => widget.viewModel.removeImageAt(index),
            primaryImageIndex: widget.viewModel.primaryImageIndex,
          ),
          if (shouldShowErrors && _imageError != null)
            ErrorText(text: _imageError!),
          // 안내 문구
          Padding(
            padding: EdgeInsets.only(
              top: context.spacingSmall,
              bottom: spacing,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '최소 ${ItemImageLimits.minImageCount}장 최대 ${ItemImageLimits.maxImageCount}장',
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: TextSecondary,
                ),
              ),
            ),
          ),
          SizedBox(height: spacing),
          // 제목 입력
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormLabel(text: '제목'),
              TextField(
                controller: widget.viewModel.titleController,
                decoration: widget.inputDecoration('상품 제목을 입력하세요').copyWith(
                  errorText: shouldShowErrors ? _titleError : null,
                ),
                onChanged: (value) {
                  // 입력 시 에러가 있으면 제거
                  if (shouldShowErrors && _titleError != null && value.trim().isNotEmpty) {
                    clearError(() => _titleError = null);
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
