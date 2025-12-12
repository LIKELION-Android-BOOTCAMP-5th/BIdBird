import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/item_add_viewmodel.dart';
import '../widget/item_add_image_section.dart';
import '../widget/item_add_price_section.dart';
import '../widget/labeled_dropdown.dart';
import '../widget/labeled_text_field.dart';

class ItemAddScreen extends StatelessWidget {
  const ItemAddScreen({super.key});

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: iconColor, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: blueColor, width: 1.5),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final ItemAddViewModel viewModel = context.watch<ItemAddViewModel>();

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '상품 이미지',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                ItemAddImagesSection(
                  viewModel: viewModel,
                  onTapAdd: () => _showImageSourceSheet(context, viewModel),
                ),
                const SizedBox(height: 24),
                LabeledTextField(
                  label: '제목',
                  controller: viewModel.titleController,
                  decoration: _inputDecoration(
                    '상품 제목을 입력하세요',
                  ).copyWith(fillColor: Colors.white),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '카테고리',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                viewModel.isLoadingKeywords
                    ? Container(
                        height: 48,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(defaultRadius),
                          border: Border.all(color: BackgroundColor),
                        ),
                        child: const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : LabeledDropdown<int>(
                        label: '',
                        value: viewModel.selectedKeywordTypeId,
                        items: viewModel.keywordTypes
                            .map(
                              (e) => DropdownMenuItem<int>(
                                value: e['id'] as int,
                                child: Text(
                                  e['title']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          viewModel.setSelectedKeywordTypeId(value);
                        },
                        decoration: _inputDecoration('카테고리 선택'),
                      ),
                const SizedBox(height: 20),
                ItemAddPriceSection(
                  viewModel: viewModel,
                  inputDecoration: _inputDecoration,
                ),
                const SizedBox(height: 20),
                LabeledDropdown<String>(
                  label: '경매 기간(시간)',
                  value: viewModel.selectedDuration,
                  items: viewModel.durations
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    viewModel.setSelectedDuration(value);
                  },
                  decoration: _inputDecoration('4시간'),
                ),
                const SizedBox(height: 20),
                LabeledTextField(
                  label: '상품 설명',
                  controller: viewModel.descriptionController,
                  maxLines: 5,
                  decoration: _inputDecoration('상품에 대한 상세한 설명을 입력하세요'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting
                    ? null
                    : () {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  disabledBackgroundColor: BorderColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                  ),
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
