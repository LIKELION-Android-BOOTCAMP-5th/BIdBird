import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/item/bottom_submit_button.dart';
import 'package:bidbird/core/widgets/item/content_input_section.dart';
import 'package:bidbird/core/widgets/item/image_upload_section.dart';
import 'package:bidbird/core/widgets/report/report_reason_section.dart';
import 'package:bidbird/core/widgets/report/report_target_section.dart';
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
    const Color primaryBlue = Color(0xFF2F5BFF);
    const Color backgroundGray = Color(0xFFF7F8FA);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textPrimary = Color(0xFF111111);
    const Color textSecondary = Color(0xFF6B7280);
    const Color errorColor = Color(0xFFE5484D);
    
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
                          ReportTargetSection(
                            itemId: widget.itemId,
                            itemTitle: widget.itemTitle,
                            targetNickname: widget.targetNickname,
                          ),
                          const SizedBox(height: 16),

                          // 신고 사유 선택
                          ReportReasonSection(viewModel: vm),
                          const SizedBox(height: 24),

                          // 상세 내용 카드
                          ContentInputSection(
                            label: '상세 내용',
                            controller: vm.contentController,
                            hintText: '발생한 상황을 간단히 설명해주세요',
                            maxLength: 500,
                            minLength: 1,
                            minLines: 6,
                            maxLines: 8,
                            successMessage: '구체적으로 작성할수록 처리 속도가 빨라집니다',
                          ),
                          const SizedBox(height: 16),

                          // 사진 첨부 카드
                          ImageUploadSection(
                            images: vm.selectedImages,
                            maxImageCount: 5,
                            onAddImage: () {
                              ImageSourceBottomSheet.show(
                                context,
                                onGalleryTap: () => vm.pickImagesFromGallery(),
                                onCameraTap: () => vm.pickImageFromCamera(),
                              );
                            },
                            onRemoveImage: (index) => vm.removeImageAt(index),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 하단 고정 버튼
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.hPadding,
                      0,
                      context.hPadding,
                      context.labelBottomPadding,
                    ),
                    child: BottomSubmitButton(
                      text: '신고 제출',
                      isEnabled: vm.canSubmit,
                      onPressed: () => _showSubmitConfirmDialog(vm),
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

