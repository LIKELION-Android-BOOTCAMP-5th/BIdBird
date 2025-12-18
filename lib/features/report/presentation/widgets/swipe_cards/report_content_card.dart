import 'package:bidbird/core/mixins/form_validation_mixin.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/sections/content_input_section.dart';
import 'package:bidbird/features/report/presentation/viewmodels/report_viewmodel.dart';
import 'package:flutter/material.dart';

/// 카드 2: 상세 내용
class ReportContentCard extends StatefulWidget {
  const ReportContentCard({
    super.key,
    required this.viewModel,
  });

  final ReportViewModel viewModel;

  @override
  State<ReportContentCard> createState() => ReportContentCardState();
}

class ReportContentCardState extends State<ReportContentCard>
    with FormValidationMixin {
  String? _contentError;
  bool _shouldShowErrors = false;

  @override
  bool get shouldShowErrors => _shouldShowErrors;

  @override
  set shouldShowErrors(bool value) {
    _shouldShowErrors = value;
  }

  void validateFields() {
    startValidation(() {
      _contentError = null;

      final content = widget.viewModel.contentController.text.trim();
      if (content.isEmpty) {
        _contentError = '상세 내용을 입력해주세요';
      } else if (content.length < 1) {
        _contentError = '최소 1자 이상 입력해주세요';
      }
    });
  }

  @override
  void clearAllErrors() {
    _contentError = null;
  }

  @override
  Widget build(BuildContext context) {
    // 내용이 입력되면 에러 제거
    final content = widget.viewModel.contentController.text.trim();
    if (content.isNotEmpty && content.length >= 1 && _contentError != null) {
      clearError(() => _contentError = null);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.hPadding,
        vertical: context.vPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentInputSection(
            label: '상세 내용',
            controller: widget.viewModel.contentController,
            hintText: '발생한 상황을 간단히 설명해주세요',
            maxLength: 500,
            minLength: 1,
            minLines: 6,
            maxLines: 8,
            successMessage: '구체적으로 작성할수록 처리 속도가 빨라집니다',
            errorMessage: _shouldShowErrors ? _contentError : null,
          ),
        ],
      ),
    );
  }
}

