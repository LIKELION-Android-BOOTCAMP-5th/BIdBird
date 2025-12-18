import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
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

class ReportTargetReasonCardState extends State<ReportTargetReasonCard> {
  String? _categoryError;
  String? _reasonError;
  bool _shouldShowErrors = false;

  void validateFields() {
    setState(() {
      _shouldShowErrors = true;
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

  void _clearErrors() {
    setState(() {
      _shouldShowErrors = false;
      _categoryError = null;
      _reasonError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacingMedium;

    // 카테고리나 사유가 선택되면 에러 제거
    if (widget.viewModel.selectedCategory != null && _categoryError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _categoryError = null;
          });
        }
      });
    }
    if (widget.viewModel.selectedReportCode != null && _reasonError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _reasonError = null;
          });
        }
      });
    }

    return SingleChildScrollView(
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
            Padding(
              padding: EdgeInsets.only(top: context.spacingSmall),
              child: Text(
                _categoryError!,
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: RedColor,
                ),
              ),
            ),
          if (_shouldShowErrors && _reasonError != null)
            Padding(
              padding: EdgeInsets.only(top: context.spacingSmall),
              child: Text(
                _reasonError!,
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: RedColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

