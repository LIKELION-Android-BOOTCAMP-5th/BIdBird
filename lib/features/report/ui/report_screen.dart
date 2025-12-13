import 'dart:io';

import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/item/add/labeled_dropdown.dart';
import 'package:bidbird/features/report/viewmodel/report_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportScreen extends StatefulWidget {
  final String? itemId;
  final String? itemTitle;
  final String targetUserId;
  final String? targetNickname;

  const ReportScreen({
    super.key,
    this.itemId,
    this.itemTitle,
    required this.targetUserId,
    this.targetNickname,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ReportViewModel>();
      if (vm.allReportTypes.isEmpty && !vm.isLoading) {
        vm.loadReportTypes();
      }
    });
  }

  void _showSubmitConfirmDialog(ReportViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AskPopup(
        content: '허위 신고 시 서비스 이용이 제한될 수 있습니다',
        noText: '취소',
        yesText: '신고하기',
        yesLogic: () async {
          Navigator.of(dialogContext).pop();
          await _onSubmit(vm);
        },
      ),
    );
  }

  Future<void> _onSubmit(ReportViewModel vm) async {
    // 전체 화면 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        const primaryBlue = Color(0xFF2F5BFF);
        const textPrimary = Color(0xFF111111);
        
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            // Pop is prevented by canPop: false
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
                const SizedBox(height: 16),
                const Text(
                  '로딩중',
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                    decorationThickness: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final success = await vm.submitReport(
      itemId: widget.itemId,
      targetUserId: widget.targetUserId,
    );

    // 로딩 다이얼로그 닫기
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (dialogContext) => AskPopup(
          content: '신고가 접수되었습니다.',
          yesText: '확인',
          yesLogic: () async {
            Navigator.of(dialogContext).pop();
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    } else {
      // 에러 메시지를 차분한 방식으로 표시
      showDialog(
        context: context,
        builder: (dialogContext) => AskPopup(
          content: vm.error ?? '신고 제출에 실패했습니다.\n다시 시도해주세요.',
          yesText: '확인',
          yesLogic: () async {
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 컬러 가이드라인 상수
    const Color primaryBlue = Color(0xFF2F5BFF);
    const Color backgroundGray = Color(0xFFF7F8FA);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textPrimary = Color(0xFF111111);
    const Color textSecondary = Color(0xFF6B7280);
    const Color textDisabled = Color(0xFF9CA3AF);
    const Color errorColor = Color(0xFFE5484D);
    const Color buttonDisabledBg = Color(0xFFE5E7EB);
    
    return ChangeNotifierProvider(
      create: (_) => ReportViewModel(),
      child: Scaffold(
        backgroundColor: backgroundGray,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '신고하기',
            style: TextStyle(color: textPrimary),
          ),
          centerTitle: true,
          backgroundColor: cardBackground,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: borderGray,
            ),
          ),
        ),
        body: Consumer<ReportViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading && vm.allReportTypes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '신고 사유를 불러오는 중...',
                      style: TextStyle(color: textPrimary),
                    ),
                  ],
                ),
              );
            }

            if (vm.error != null && vm.allReportTypes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: errorColor),
                    const SizedBox(height: 16),
                    const Text(
                      '신고 사유를 불러올 수 없습니다.',
                      style: TextStyle(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.error ?? '',
                      style: const TextStyle(fontSize: 12, color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.loadReportTypes(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 신고 대상 정보 카드
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: defaultBorder,
                              border: Border.all(
                                color: borderGray,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '신고 대상',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (widget.itemId != null) ...[
                                  Text(
                                    widget.itemTitle ?? '알 수 없음',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  widget.targetNickname ?? '알 수 없음',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 신고 사유 선택
                          if (vm.categories.isEmpty && !vm.isLoading)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBackground,
                                borderRadius: defaultBorder,
                                border: Border.all(
                                  color: borderGray,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '신고 사유를 불러올 수 없습니다.',
                                    style: TextStyle(color: errorColor),
                                  ),
                                  if (vm.error != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      vm.error!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => vm.loadReportTypes(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('다시 시도'),
                                  ),
                                ],
                              ),
                            )
                          else if (vm.categories.isEmpty && vm.isLoading)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBackground,
                                borderRadius: defaultBorder,
                                border: Border.all(
                                  color: borderGray,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '신고 사유를 불러오는 중...',
                                    style: TextStyle(color: textSecondary),
                                  ),
                                ],
                              ),
                            )
                          else
                            LabeledDropdown<String>(
                              label: '',
                              value: vm.selectedCategory,
                              items: vm.categories.map((category) {
                                try {
                                  final firstType = vm.allReportTypes
                                      .firstWhere((e) => e.category == category);
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(firstType.categoryName),
                                  );
                                } catch (e) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  vm.selectCategory(value);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: '신고 사유를 선택하세요',
                                hintStyle: TextStyle(
                                  color: textDisabled,
                                  fontSize: context.fontSizeSmall,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: context.inputPadding,
                                  vertical: context.inputPadding,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(defaultRadius),
                                  borderSide: const BorderSide(
                                    color: borderGray,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(defaultRadius),
                                  borderSide: BorderSide(
                                    color: vm.selectedCategory != null ? primaryBlue : borderGray,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(defaultRadius),
                                  borderSide: const BorderSide(
                                    color: primaryBlue,
                                    width: 1,
                                  ),
                                ),
                                filled: true,
                                fillColor: cardBackground,
                              ),
                            ),

                          // 소분류 선택 (항상 표시, 대분류 선택 전까지 비활성화)
                          const SizedBox(height: 16),
                          LabeledDropdown<String>(
                            label: '',
                            value: vm.selectedReportCode,
                            items: vm.selectedCategory == null
                                ? <DropdownMenuItem<String>>[]
                                : vm.selectedCategoryReports.isEmpty
                                    ? <DropdownMenuItem<String>>[]
                                    : vm.selectedCategoryReports.map((type) {
                                        return DropdownMenuItem<String>(
                                          value: type.reportType,
                                          child: Text(type.description),
                                        );
                                      }).toList(),
                            onChanged: vm.selectedCategory == null
                                ? (_) {}
                                : (value) {
                                    if (value != null) {
                                      vm.selectReportCode(value);
                                    }
                                  },
                            decoration: InputDecoration(
                              hintText: vm.selectedCategory == null
                                  ? '대분류를 먼저 선택해주세요'
                                  : '신고 사유를 선택하세요',
                              hintStyle: TextStyle(
                                color: textDisabled,
                                fontSize: context.fontSizeSmall,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: context.inputPadding,
                                vertical: context.inputPadding,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(defaultRadius),
                                borderSide: const BorderSide(
                                  color: borderGray,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(defaultRadius),
                                borderSide: BorderSide(
                                  color: vm.selectedReportCode != null ? primaryBlue : borderGray,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(defaultRadius),
                                borderSide: const BorderSide(
                                  color: borderGray,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(defaultRadius),
                                borderSide: const BorderSide(
                                  color: primaryBlue,
                                  width: 1,
                                ),
                              ),
                              filled: true,
                              fillColor: vm.selectedCategory == null
                                  ? backgroundGray
                                  : cardBackground,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 상세 내용 카드
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: defaultBorder,
                              border: Border.all(
                                color: borderGray,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '상세 내용',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: vm.contentController,
                                  maxLines: 8,
                                  minLines: 6,
                                  maxLength: 500,
                                  cursorColor: primaryBlue,
                                  style: const TextStyle(
                                    color: textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '발생한 상황을 간단히 설명해주세요',
                                    hintStyle: TextStyle(
                                      color: textDisabled,
                                      fontSize: context.fontSizeSmall,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    counterText: '',
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      vm.contentController.text.length >= 10
                                          ? '구체적으로 작성할수록 처리 속도가 빨라집니다'
                                          : '10자 이상 입력해주세요',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: vm.contentController.text.length >= 10
                                            ? textSecondary
                                            : errorColor,
                                      ),
                                    ),
                                    Text(
                                      '${vm.contentController.text.length}/500',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: vm.contentController.text.length >= 10
                                            ? textDisabled
                                            : errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 사진 첨부 카드
                          Container(
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
                                      color: textSecondary,
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
                                            ? textSecondary
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
                          ),

                        ],
                      ),
                    ),
                  ),

                  // 하단 고정 버튼
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: vm.canSubmit
                            ? () => _showSubmitConfirmDialog(vm)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: buttonDisabledBg,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: textDisabled,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(defaultRadius),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '신고 제출',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}