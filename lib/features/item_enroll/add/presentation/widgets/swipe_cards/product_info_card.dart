import 'package:bidbird/core/mixins/form_validation_mixin.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
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

class ProductInfoCardState extends State<ProductInfoCard>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  static const String _imageLimitText =
      '최소 ${ItemImageLimits.minImageCount}장 최대 ${ItemImageLimits.maxImageCount}장';

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
  void didUpdateWidget(ProductInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 이미지가 추가되었을 때만 체크하여 에러 제거
    if (widget.viewModel.selectedImages.length >
        oldWidget.viewModel.selectedImages.length) {
      if (shouldShowErrors && _imageError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            clearError(() => _imageError = null);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // keep-alive
    final spacing = context.spacingMedium;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                _imageLimitText,
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
                maxLength: ItemTextLimits.maxTitleLength,
                decoration: widget
                    .inputDecoration('상품 제목을 입력하세요')
                    .copyWith(
                      errorText: shouldShowErrors ? _titleError : null,
                      counterText: '', // 기본 카운터 숨기기
                    ),
                onChanged: (value) {
                  // 입력 시 에러가 있으면 제거
                  if (shouldShowErrors &&
                      _titleError != null &&
                      value.trim().isNotEmpty) {
                    clearError(() => _titleError = null);
                  }
                },
              ),
              // 글자수 표시
              Padding(
                padding: EdgeInsets.only(top: context.spacingSmall),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _CharacterCounter(
                    controller: widget.viewModel.titleController,
                    maxLength: ItemTextLimits.maxTitleLength,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// 글자수 카운터 위젯 - 불필요한 재빌드 최소화
class _CharacterCounter extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;

  const _CharacterCounter({required this.controller, required this.maxLength});

  @override
  State<_CharacterCounter> createState() => _CharacterCounterState();
}

class _CharacterCounterState extends State<_CharacterCounter> {
  late int _length;

  @override
  void initState() {
    super.initState();
    _length = widget.controller.text.length;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final newLength = widget.controller.text.length;
    if (_length != newLength) {
      setState(() {
        _length = newLength;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_length/${widget.maxLength}',
      style: TextStyle(fontSize: context.fontSizeSmall, color: TextSecondary),
    );
  }
}
