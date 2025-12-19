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
  void initState() {
    super.initState();
    // 컨트롤러 변경 감지를 위한 리스너 추가
    widget.viewModel.contentController.addListener(_handleContentChange);
  }

  @override
  void dispose() {
    widget.viewModel.contentController.removeListener(_handleContentChange);
    super.dispose();
  }

  void _handleContentChange() {
    final content = widget.viewModel.contentController.text.trim();
    // 내용이 입력되어 에러가 있으면 제거
    if (content.isNotEmpty && content.length >= 1 && _contentError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          clearError(() => _contentError = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.hPadding,
        vertical: context.vPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ContentInputSection(
              label: '상세 내용',
              controller: widget.viewModel.contentController,
              hintText: '발생한 상황을 간단히 설명해주세요',
              maxLength: 500,
              minLength: 1,
              minLines: null,
              maxLines: null,
              successMessage: '구체적으로 작성할수록 처리 속도가 빨라집니다',
              errorMessage: _shouldShowErrors ? _contentError : null,
            ),
          ),
        ],
      ),
    );
  }
}

