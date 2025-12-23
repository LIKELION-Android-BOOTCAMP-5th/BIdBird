// import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
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

/// Report Form Section - 다단계 신고 폼 조립
/// 
/// PageView를 이용한 3단계 신고 프로세스:
/// 1️⃣ 신고 대상 및 사유 선택
/// 2️⃣ 상세 내용 입력
/// 3️⃣ 사진 첨부
class ReportFormSection extends StatefulWidget {
  final ReportViewModel viewModel;
  final String? itemId;
  final String? itemTitle;
  final String targetUserId;
  final String? targetNickname;

  const ReportFormSection({
    super.key,
    required this.viewModel,
    this.itemId,
    this.itemTitle,
    required this.targetUserId,
    this.targetNickname,
  });

  @override
  State<ReportFormSection> createState() => _ReportFormSectionState();
}

class _ReportFormSectionState extends State<ReportFormSection> {
  final PageController _pageController = PageController();
  final GlobalKey<ReportTargetReasonCardState> _targetReasonCardKey =
      GlobalKey<ReportTargetReasonCardState>();
  final GlobalKey<ReportContentCardState> _contentCardKey =
      GlobalKey<ReportContentCardState>();

  int _currentStep = 0;

  static const List<String> _stepLabels = [
    '신고 사유',
    '상세 내용',
    '사진 첨부',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  bool _canGoToNextStep() {
    switch (_currentStep) {
      case 0:
        return widget.viewModel.selectedCategory != null &&
            widget.viewModel.selectedReportCode != null;
      case 1:
        final content = widget.viewModel.contentController.text.trim();
        return content.isNotEmpty && content.length >= 1;
      case 2:
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

  void _showImageSourceSheet(BuildContext context) {
    ImageSourceBottomSheet.show(
      context,
      onGalleryTap: () async {
        await widget.viewModel.pickImagesFromGallery();
      },
      onCameraTap: () async {
        await widget.viewModel.pickImageFromCamera();
      },
    );
  }

  void _showSubmitConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AskPopup(
        content: '허위 신고 시 서비스 이용이 제한될 수 있습니다',
        noText: '취소',
        yesText: '신고하기',
        yesLogic: () async {
          Navigator.of(dialogContext).pop();
          await _onSubmit();
        },
      ),
    );
  }

  Future<void> _onSubmit() async {
    // 로딩 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(PrimaryBlue),
            ),
            SizedBox(height: 16),
            Text(
              '로딩중',
              style: TextStyle(
                fontSize: 14,
                color: TextPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    final success = await widget.viewModel.submitReport(
      itemId: widget.itemId,
      targetUserId: widget.targetUserId,
    );

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
      showDialog(
        context: context,
        builder: (dialogContext) => AskPopup(
          content: widget.viewModel.error ??
              '신고 제출에 실패했습니다.\n다시 시도해주세요.',
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
    // final horizontalPadding = context.hPadding; // 미사용 변수 제거
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Column(
        children: [
          // Step Indicator
          StepIndicator(
            currentStep: _currentStep,
            totalSteps: 3,
            stepLabels: _stepLabels,
          ),

          // Form Pages (PageView)
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: isKeyboardVisible || !_canGoToNextStep()
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (index) {
                // Swipe 검증
                if (index > _currentStep) {
                  if (_currentStep == 0) {
                    _targetReasonCardKey.currentState?.validateFields();
                    if (!_canGoToNextStep()) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _pageController.jumpToPage(_currentStep);
                        }
                      });
                      return;
                    }
                  } else if (_currentStep == 1) {
                    _contentCardKey.currentState?.validateFields();
                    if (!_canGoToNextStep()) {
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
                // Card 1: 신고 대상 및 사유
                ReportTargetReasonCard(
                  key: _targetReasonCardKey,
                  viewModel: widget.viewModel,
                  itemId: widget.itemId,
                  itemTitle: widget.itemTitle,
                  targetNickname: widget.targetNickname ?? '알 수 없음',
                ),

                // Card 2: 상세 내용
                ReportContentCard(
                  key: _contentCardKey,
                  viewModel: widget.viewModel,
                ),

                // Card 3: 사진 첨부
                ReportImageCard(
                  viewModel: widget.viewModel,
                  onImageSourceTap: () => _showImageSourceSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildButtonBar(),
    );
  }

  Widget _buildButtonBar() {
    final horizontalPadding = context.hPadding;

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: chatItemCardBackground,
          boxShadow: [
            BoxShadow(
              color: shadowLow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _currentStep == 0
            ? _buildSingleButton()
            : _buildDoubleButtons(),
      ),
    );
  }

  Widget _buildSingleButton() {
    return PrimaryButton(
      text: _getNextButtonText(),
      onPressed: () {
        if (_currentStep < 2) {
          _goToStep(_currentStep + 1);
        } else {
          _showSubmitConfirmDialog();
        }
      },
      isEnabled: _canGoToNextStep() && !widget.viewModel.isLoading,
      width: double.infinity,
    );
  }

  Widget _buildDoubleButtons() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SecondaryButton(
            text: '이전',
            onPressed: () => _goToStep(_currentStep - 1),
            width: null,
          ),
        ),
        SizedBox(width: context.spacingSmall),
        Expanded(
          child: PrimaryButton(
            text: _getNextButtonText(),
            onPressed: () {
              if (_currentStep == 1) {
                _contentCardKey.currentState?.validateFields();
                if (!_canGoToNextStep()) {
                  return;
                }
              }

              if (_currentStep < 2) {
                _goToStep(_currentStep + 1);
              } else {
                _showSubmitConfirmDialog();
              }
            },
            isEnabled: !widget.viewModel.isLoading,
            width: null,
          ),
        ),
      ],
    );
  }
}
