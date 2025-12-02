import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
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
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
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
                        viewModel.selectedKeywordTypeId = value;
                        viewModel.notifyListeners();
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
                value: viewModel.selectedDuration,
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
                  viewModel.selectedDuration = value;
                  viewModel.notifyListeners();
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
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F6FA),
                  borderRadius: defaultBorder,
                  border: Border.all(color: const Color(0xffE0E3EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '등록 약관',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. 판매자는 시작가와 즉시 구매가(선택 입력)를 정확하게 입력해야 합니다. 허위 정보 입력은 금지됩니다.\n'
                      '2. 등록된 매물은 경매 시작 시점부터 경매 종료까지 임의 수정 또는 삭제가 제한될 수 있습니다.\n'
                      '3. 경매 종료 후 낙찰자가 존재할 경우, 판매자는 해당 낙찰자에게 매물을 반드시 인도해야 합니다. 임의 취소는 허용되지 않습니다.\n'
                      '4. 낙찰 금액 또는 즉시 구매 금액은 플랫폼 정책에 따라 결제·정산 절차가 진행됩니다. 판매자는 이에 동의한 것으로 간주됩니다.\n'
                      '5. 매물 설명, 사진, 상태 정보 등 모든 기재 내용은 사실에 기반해야 합니다. 허위 또는 과장 기재로 인해 발생하는 문제는 판매자 책임입니다.\n'
                      '6. 불법 물품, 타인의 권리를 침해하는 물품, 거래가 제한된 물품은 등록이 금지됩니다. 위반 시 매물 삭제 및 서비스 이용 제한이 적용될 수 있습니다.\n'
                      '7. 거래 과정에서 분쟁이 발생할 경우, 플랫폼의 분쟁 처리 기준 및 검증 절차가 우선 적용됩니다. 판매자는 관련 자료 제출 요청에 협조해야 합니다.\n'
                      '8. 매물 등록 시점부터 거래 종료까지 모든 기록은 운영 정책에 따라 보관·검토될 수 있습니다.\n'
                      '9. 약관에 위배되는 행위가 확인될 경우, 플랫폼은 매물 삭제, 거래 중단, 계정 제재 등의 조치를 시행할 수 있습니다.\n'
                      '10. 본 약관은 등록 시점 기준으로 적용되며, 운영 정책에 따라 변경될 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xff6E7485),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: viewModel.agreed,
                    onChanged: (value) {
                      viewModel.agreed = value ?? false;
                      viewModel.notifyListeners();
                    },
                    activeColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '위 약관에 동의합니다.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  viewModel.agreed && !viewModel.isSubmitting
                      ? () => viewModel.submit(context)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                disabledBackgroundColor: const Color(0xffD0D4DC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '등록하기',
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