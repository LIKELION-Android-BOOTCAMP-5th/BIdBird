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
import 'package:provider/provider.dart';

/// 카드 1: 상품 정보
class ProductInfoCard extends StatefulWidget {
  const ProductInfoCard({
    super.key,
    required this.viewModel,
    required this.onImageSourceTap,
    required this.inputDecoration,
    this.addPhotoKey,
    this.addTitleKey,
  });

  final ItemAddViewModel viewModel;
  final VoidCallback onImageSourceTap;
  final InputDecoration Function(String hint) inputDecoration;
  final GlobalKey? addPhotoKey;
  final GlobalKey? addTitleKey;

  @override
  State<ProductInfoCard> createState() => ProductInfoCardState();
}

class ProductInfoCardState extends State<ProductInfoCard>
    with FormValidationMixin {
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
  Widget build(BuildContext context) {
    // 반응형 값 캐싱
    final spacing = context.spacingMedium;
    final hPadding = context.hPadding;
    final vPadding = context.vPadding;
    final spacingSmall = context.spacingSmall;
    final fontSizeSmall = context.fontSizeSmall;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 업로드 섹션
          FormLabel(text: '상품 이미지'),
          Consumer<ItemAddViewModel>(
            builder: (context, vm, _) {
              return SquareImageUploadSection(
                key: widget.addPhotoKey,
                images: vm.selectedImages,
                onImageSourceTap: widget.onImageSourceTap,
                onImageTap: (index) => vm.setPrimaryImage(index),
                onRemoveImage: (index) => vm.removeImageAt(index),
                primaryImageIndex: vm.primaryImageIndex,
              );
            },
          ),
          if (shouldShowErrors && _imageError != null)
            ErrorText(text: _imageError!),
          // 안내 문구
          Padding(
            padding: EdgeInsets.only(top: spacingSmall, bottom: spacing),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _imageLimitText,
                style: TextStyle(fontSize: fontSizeSmall, color: TextSecondary),
              ),
            ),
          ),
          SizedBox(height: spacing),
          // 제목 입력
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormLabel(text: '제목'),
              RepaintBoundary(
                child: TextField(
                  key: widget.addTitleKey,
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
              ),
              // 글자수 표시
              Padding(
                padding: EdgeInsets.only(top: spacingSmall),
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
    final fontSizeSmall = context.fontSizeSmall;
    return Text(
      '$_length/${widget.maxLength}',
      style: TextStyle(fontSize: fontSizeSmall, color: TextSecondary),
    );
  }
}
