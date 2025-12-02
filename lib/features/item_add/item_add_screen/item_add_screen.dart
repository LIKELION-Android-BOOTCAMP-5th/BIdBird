import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/widgets/components/pop_up/confirm_cancel_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/confirm_only_popup.dart';
import 'package:provider/provider.dart';

import '../item_add_viewmoel/item_add_viewmoel.dart';

class ItemAddScreen extends StatelessWidget {
  const ItemAddScreen({super.key});

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xffC4C4C4),
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: const BorderSide(color: Color(0xffE5E5E5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: const BorderSide(color: Color(0xffE5E5E5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: const BorderSide(color: blueColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, ItemAddViewModel viewModel) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(defaultRadius)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await viewModel.pickImagesFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('사진 찍기'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await viewModel.pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ItemAddViewModel viewModel = context.watch<ItemAddViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('매물 등록'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('상품 이미지'),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffF8F8FA),
                  borderRadius: defaultBorder,
                  border: Border.all(color: const Color(0xffE5E5E5)),
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
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '이미지를 업로드하세요',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xffB0B3BC),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        itemBuilder: (context, index) {
                          final image = viewModel.selectedImages[index];
                          return ClipRRect(
                            borderRadius: defaultBorder,
                            child: Image.file(
                              File(image.path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: viewModel.selectedImages.length,
                      ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () => _showImageSourceSheet(context, viewModel),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(defaultRadius),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(defaultRadius),
                        ),
                        child: Text(
                          '${viewModel.selectedImages.length}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('제목'),
              TextField(
                controller: viewModel.titleController,
                decoration: _inputDecoration('상품 제목을 입력하세요'),
              ),
              const SizedBox(height: 20),
              _buildLabel('카테고리'),
              viewModel.isLoadingKeywords
                  ? Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(defaultRadius),
                        border: Border.all(color: const Color(0xffE5E5E5)),
                      ),
                      child: const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: viewModel.selectedKeywordTypeId,
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
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('시작가'),
                        TextField(
                          controller: viewModel.startPriceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('시작 가격 입력'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('즉시 입찰가'),
                        TextField(
                          controller: viewModel.instantPriceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('즉시 입찰가 입력'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('경매 기간(시간)'),
              DropdownButtonFormField<String>(
                initialValue: viewModel.selectedDuration,
                items: viewModel.durations
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(
                          e,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
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
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('상품 설명'),
              TextField(
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
                        builder: (_) => ConfirmCancelPopup(
                          title: '저장하시겠습니까?',
                          onConfirm: () {
                            showDialog(
                              context: context,
                              builder: (_) => ConfirmOnlyPopup(
                                title: '알림',
                                description:
                                    '매물 등록하기로 이동하여 최종 등록을 진행해 주세요.',
                                confirmText: '확인',
                                onConfirm: () {
                                  viewModel.submit(context);
                                },
                              ),
                            );
                          },
                          onCancel: () {},
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                disabledBackgroundColor: const Color(0xffD0D4DC),
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
    );
  }
}