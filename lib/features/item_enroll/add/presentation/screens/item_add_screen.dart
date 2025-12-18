import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/auction_duration_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/category_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/item_add_viewmodel.dart';
import 'package:bidbird/core/widgets/item/components/buttons/bottom_submit_button.dart';
import 'package:bidbird/core/widgets/item/components/sections/content_input_section.dart';
import 'package:bidbird/core/widgets/item/components/sections/image_upload_section.dart';
import 'package:bidbird/features/item_enroll/add/presentation/widgets/item_add_price_section.dart';
import 'package:bidbird/core/widgets/item/components/fields/labeled_text_field.dart';

class ItemAddScreen extends StatelessWidget {
  const ItemAddScreen({super.key});

  InputDecoration _inputDecoration(String hint, BuildContext? context) {
    final hintFontSize = context?.fontSizeSmall ?? 13;
    final horizontalPadding = context?.inputPadding ?? 12;
    final verticalPadding = context?.inputPadding ?? 12;
    final borderWidth = context?.borderWidth ?? 1.5;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: iconColor, fontSize: hintFontSize),
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: const BorderSide(color: BackgroundColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: const BorderSide(color: BackgroundColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: blueColor, width: borderWidth),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  void _showImageSourceSheet(BuildContext context, ItemAddViewModel viewModel) {
    ImageSourceBottomSheet.show(
      context,
      onGalleryTap: () async {
        await viewModel.pickImagesFromGallery();
      },
      onCameraTap: () async {
        await viewModel.pickImageFromCamera();
      },
      onVideoTap: () async {
        await viewModel.pickVideoFromGallery();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ItemAddViewModel viewModel = context.watch<ItemAddViewModel>();

    // Responsive values
    final horizontalPadding = context.hPadding;
    final verticalPadding = context.vPadding;
    final spacing = context.spacingMedium;
    final labelFontSize = context.fontSizeMedium;
    final bottomPadding = context.bottomPadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('매물 등록'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                  child: Text(
                    '상품 이미지',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                ImageUploadSection(
                  images: viewModel.selectedImages,
                  maxImageCount: 10,
                  primaryImageIndex: viewModel.primaryImageIndex,
                  onPrimaryImageTap: (index) => viewModel.setPrimaryImage(index),
                  supportVideo: true,
                  onAddImage: () => _showImageSourceSheet(context, viewModel),
                  onRemoveImage: (index) => viewModel.removeImageAt(index),
                ),
                SizedBox(height: spacing),
                LabeledTextField(
                  label: '제목',
                  controller: viewModel.titleController,
                  decoration: _inputDecoration(
                    '상품 제목을 입력하세요',
                    context,
                  ).copyWith(fillColor: Colors.white),
                ),
                SizedBox(height: spacing),
                Padding(
                  padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                  child: Text(
                    '카테고리',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                viewModel.isLoadingKeywords
                    ? Container(
                        height: context.heightRatio(0.06, min: 44.0, max: 56.0), // 특수 케이스: 로딩 컨테이너 높이
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.inputPadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(defaultRadius),
                          border: Border.all(color: BackgroundColor),
                        ),
                        child: SizedBox(
                          height: context.iconSizeSmall,
                          width: context.iconSizeSmall,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          CategoryBottomSheet.show(
                            context,
                            categories: viewModel.keywordTypes,
                            selectedCategoryId: viewModel.selectedKeywordTypeId,
                            onCategorySelected: (id) {
                              viewModel.setSelectedKeywordTypeId(id);
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
                              color: viewModel.selectedKeywordTypeId != null
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
                                    viewModel.selectedKeywordTypeId != null
                                        ? viewModel.keywordTypes
                                            .firstWhere(
                                              (e) => e.id == viewModel.selectedKeywordTypeId,
                                              orElse: () => viewModel.keywordTypes.first,
                                            )
                                            .title
                                        : '카테고리 선택',
                                    style: TextStyle(
                                      fontSize: context.fontSizeSmall,
                                      color: viewModel.selectedKeywordTypeId != null
                                          ? textColor
                                          : iconColor,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: viewModel.selectedKeywordTypeId != null
                                    ? blueColor
                                    : iconColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                SizedBox(height: spacing),
                ItemAddPriceSection(
                  viewModel: viewModel,
                  inputDecoration: (hint) => _inputDecoration(hint, context),
                ),
                SizedBox(height: spacing),
                Padding(
                  padding: EdgeInsets.only(bottom: context.labelBottomPadding),
                  child: Text(
                    '경매 기간(시간)',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AuctionDurationBottomSheet.show(
                      context,
                      durations: viewModel.durations,
                      selectedDuration: viewModel.selectedDuration,
                      onDurationSelected: (duration) {
                        viewModel.setSelectedDuration(duration);
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
                        color: viewModel.selectedDuration != null
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
                              viewModel.selectedDuration ?? '경매 기간 선택',
                              style: TextStyle(
                                fontSize: context.fontSizeSmall,
                                color: viewModel.selectedDuration != null
                                    ? textColor
                                    : iconColor,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: viewModel.selectedDuration != null
                              ? blueColor
                              : iconColor,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                ContentInputSection(
                  label: '상품 설명',
                  controller: viewModel.descriptionController,
                  hintText: '상품에 대한 상세한 설명을 입력하세요',
                  maxLength: 1000,
                  minLines: 5,
                  maxLines: 8,
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              context.labelBottomPadding,
            ),
            child: BottomSubmitButton(
              text: '저장하기',
              isEnabled: viewModel.validate() == null && !viewModel.isSubmitting,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AskPopup(
                    content: '저장하시겠습니까?',
                    noText: '취소',
                    yesLogic: () async {
                      Navigator.of(context).pop();
                      await viewModel.submit(context);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
