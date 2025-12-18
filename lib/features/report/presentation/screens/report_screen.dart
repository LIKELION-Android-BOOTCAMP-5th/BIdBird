import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/item/components/buttons/primary_button.dart';
import 'package:bidbird/core/widgets/item/components/buttons/secondary_button.dart';
import 'package:bidbird/features/item_enroll/add/presentation/widgets/step_indicator.dart';
import 'package:bidbird/features/report/presentation/viewmodels/report_viewmodel.dart';
import 'package:bidbird/features/report/presentation/widgets/swipe_cards/report_content_card.dart';
import 'package:bidbird/features/report/presentation/widgets/swipe_cards/report_image_card.dart';
import 'package:bidbird/features/report/presentation/widgets/swipe_cards/report_target_reason_card.dart';
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
  final PageController _pageController = PageController();
  final GlobalKey<ReportTargetReasonCardState> _targetReasonCardKey = GlobalKey<ReportTargetReasonCardState>();
  final GlobalKey<ReportContentCardState> _contentCardKey = GlobalKey<ReportContentCardState>();
  int _currentStep = 0;

  static const List<String> _stepLabels = [
    '신고 사유',
    '상세 내용',
    '사진 첨부',
  ];

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

  void _showImageSourceSheet(BuildContext context, ReportViewModel viewModel) {
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

  void _goToStep(int step) {
    if (step >= 0 && step < 3) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canGoToNextStep(ReportViewModel viewModel) {
    switch (_currentStep) {
      case 0:
        // 카드 1: 신고 사유와 상세 사유 필수
        return viewModel.selectedCategory != null &&
            viewModel.selectedReportCode != null;
      case 1:
        // 카드 2: 상세 내용 필수 (최소 1자)
        final content = viewModel.contentController.text.trim();
        return content.isNotEmpty && content.length >= 1;
      case 2:
        // 카드 3: 사진은 선택사항이므로 항상 통과
        return true;
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
        return '다음';
      case 2:
        return '신고하기';
      default:
        return '다음';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    return ChangeNotifierProvider(
      create: (_) => ReportViewModel(),
      child: Selector<ReportViewModel, ({
        bool isLoading,
        int allReportTypesLength,
        String? error,
        String? selectedCategory,
        String? selectedReportCode,
        bool canSubmit,
        int selectedImagesLength,
        bool isUploadingImages,
      })>(
        selector: (_, vm) => (
          isLoading: vm.isLoading,
          allReportTypesLength: vm.allReportTypes.length,
          error: vm.error,
          selectedCategory: vm.selectedCategory,
          selectedReportCode: vm.selectedReportCode,
          canSubmit: vm.canSubmit,
          selectedImagesLength: vm.selectedImages.length,
          isUploadingImages: vm.isUploadingImages,
        ),
        builder: (context, data, _) {
          final vm = context.read<ReportViewModel>();
          
          // 로딩 상태 처리
          if (data.isLoading && data.allReportTypesLength == 0) {
            return Scaffold(
              backgroundColor: BackgroundColor,
              appBar: AppBar(
                title: const Text('신고하기'),
                centerTitle: true,
                backgroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(blueColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '신고 사유를 불러오는 중...',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            );
          }

          // 에러 상태 처리
          if (data.error != null && data.allReportTypesLength == 0) {
            return Scaffold(
              backgroundColor: BackgroundColor,
              appBar: AppBar(
                title: const Text('신고하기'),
                centerTitle: true,
                backgroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: RedColor),
                    const SizedBox(height: 16),
                    Text(
                      '신고 사유를 불러올 수 없습니다.',
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.error ?? '',
                      style: TextStyle(fontSize: 12, color: iconColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 120,
                      child: PrimaryButton(
                        text: '다시 시도',
                        onPressed: () => vm.loadReportTypes(),
                        width: 120,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final horizontalPadding = context.hPadding;
          
          // 키보드 감지 - MediaQuery를 직접 사용하여 setState 없이 처리
          final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

          return Scaffold(
            backgroundColor: BackgroundColor,
            appBar: AppBar(
              title: const Text('신고하기'),
              centerTitle: true,
              backgroundColor: Colors.white,
            ),
            body: Column(
              children: [
                // 스텝 인디케이터
                StepIndicator(
                  currentStep: _currentStep,
                  totalSteps: 3,
                  stepLabels: _stepLabels,
                ),
                // 카드 영역
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: isKeyboardVisible || !_canGoToNextStep(vm)
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    onPageChanged: (index) {
                      // 스와이프로 다음 페이지로 넘어가려고 할 때 검증
                      if (index > _currentStep) {
                        // 첫 번째 카드에서 두 번째 카드로 넘어가려고 할 때
                        if (_currentStep == 0) {
                          _targetReasonCardKey.currentState?.validateFields();
                          if (!_canGoToNextStep(vm)) {
                            // 검증 실패 시 즉시 이전 페이지로 돌아감
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _pageController.jumpToPage(_currentStep);
                              }
                            });
                            return;
                          }
                        }
                        // 두 번째 카드에서 세 번째 카드로 넘어가려고 할 때
                        else if (_currentStep == 1) {
                          _contentCardKey.currentState?.validateFields();
                          if (!_canGoToNextStep(vm)) {
                            // 검증 실패 시 즉시 이전 페이지로 돌아감
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _pageController.jumpToPage(_currentStep);
                              }
                            });
                            return;
                          }
                        }
                      }
                      
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      // 카드 1: 신고 대상 및 사유
                      ReportTargetReasonCard(
                        key: _targetReasonCardKey,
                        viewModel: vm,
                        itemId: widget.itemId,
                        itemTitle: widget.itemTitle,
                        targetNickname: widget.targetNickname ?? '알 수 없음',
                      ),
                      // 카드 2: 상세 내용
                      ReportContentCard(
                        key: _contentCardKey,
                        viewModel: vm,
                      ),
                      // 카드 3: 사진 첨부
                      ReportImageCard(
                        viewModel: vm,
                        onImageSourceTap: () => _showImageSourceSheet(context, vm),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                height: 72,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: shadowLow,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _currentStep == 0
                    ? PrimaryButton(
                        text: _getNextButtonText(),
                        onPressed: () {
                          if (_currentStep < 2) {
                            // 다음 단계로 이동
                            _goToStep(_currentStep + 1);
                          } else {
                            // 최종 신고
                            _showSubmitConfirmDialog(vm);
                          }
                        },
                        isEnabled: _canGoToNextStep(vm) && !vm.isLoading,
                        width: double.infinity,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 이전 버튼
                          Expanded(
                            child: SecondaryButton(
                              text: '이전',
                              onPressed: () => _goToStep(_currentStep - 1),
                              width: null,
                            ),
                          ),
                          SizedBox(width: context.spacingSmall),
                          // 다음/신고하기 버튼
                          Expanded(
                            child: PrimaryButton(
                              text: _getNextButtonText(),
                              onPressed: () {
                                // 상세 내용 카드에서 다음 버튼을 눌렀을 때 검증
                                if (_currentStep == 1) {
                                  _contentCardKey.currentState?.validateFields();
                                  // 검증 후 다시 확인
                                  if (!_canGoToNextStep(vm)) {
                                    return;
                                  }
                                }
                                
                                if (_currentStep < 2) {
                                  // 다음 단계로 이동
                                  _goToStep(_currentStep + 1);
                                } else {
                                  // 최종 신고
                                  _showSubmitConfirmDialog(vm);
                                }
                              },
                              isEnabled: !vm.isLoading,
                              width: null,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
