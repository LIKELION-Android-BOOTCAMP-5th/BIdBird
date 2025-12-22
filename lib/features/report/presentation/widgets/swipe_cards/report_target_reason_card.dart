import 'package:bidbird/core/mixins/form_validation_mixin.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/fields/error_text.dart';
import 'package:bidbird/features/report/presentation/viewmodels/report_viewmodel.dart';
import 'package:bidbird/features/report/presentation/widgets/report_reason_section.dart';
import 'package:bidbird/features/report/presentation/widgets/report_target_section.dart';
import 'package:flutter/material.dart';

/// 카드 1: 신고 대상 및 사유
class ReportTargetReasonCard extends StatefulWidget {
  const ReportTargetReasonCard({
    super.key,
    required this.viewModel,
    required this.itemId,
    required this.itemTitle,
    required this.targetNickname,
  });

  final ReportViewModel viewModel;
  final String? itemId;
  final String? itemTitle;
  final String? targetNickname;

  @override
  State<ReportTargetReasonCard> createState() => ReportTargetReasonCardState();
}

class ReportTargetReasonCardState extends State<ReportTargetReasonCard>
    with FormValidationMixin {
  String? _categoryError;
  String? _reasonError;
  bool _shouldShowErrors = false;

  @override
  bool get shouldShowErrors => _shouldShowErrors;

  @override
  set shouldShowErrors(bool value) {
    _shouldShowErrors = value;
  }

  void validateFields() {
    startValidation(() {
      _categoryError = null;
      _reasonError = null;

      if (widget.viewModel.selectedCategory == null) {
        _categoryError = '신고 사유를 선택해주세요';
      }

      if (widget.viewModel.selectedReportCode == null) {
        _reasonError = '상세 사유를 선택해주세요';
      }
    });
  }

  @override
  void clearAllErrors() {
    _categoryError = null;
    _reasonError = null;
  }

  @override
  void didUpdateWidget(ReportTargetReasonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 카테고리나 사유가 선택되었을 때만 체크하여 에러 제거
    if (widget.viewModel.selectedCategory != null &&
        oldWidget.viewModel.selectedCategory == null &&
        _categoryError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          clearError(() => _categoryError = null);
        }
      });
    }
    if (widget.viewModel.selectedReportCode != null &&
        oldWidget.viewModel.selectedReportCode == null &&
        _reasonError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          clearError(() => _reasonError = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // 신고 대상 정보 카드
          ReportTargetSection(
            itemId: widget.itemId,
            itemTitle: widget.itemTitle,
            targetNickname: widget.targetNickname,
          ),
          SizedBox(height: spacing),

          // 신고 사유 선택
          ReportReasonSection(viewModel: widget.viewModel),
          if (_shouldShowErrors && _categoryError != null)
            ErrorText(text: _categoryError!),
          if (_shouldShowErrors && _reasonError != null)
            ErrorText(text: _reasonError!),
        ],
      ),
    );
  }
}
