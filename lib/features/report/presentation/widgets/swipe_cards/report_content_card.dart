import 'package:bidbird/core/utils/ui_set/colors_style.dart';
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

class ReportContentCardState extends State<ReportContentCard> {
  String? _contentError;
  bool _shouldShowErrors = false;

  void validateFields() {
    setState(() {
      _shouldShowErrors = true;
      _contentError = null;

      final content = widget.viewModel.contentController.text.trim();
      if (content.isEmpty) {
        _contentError = '상세 내용을 입력해주세요';
      } else if (content.length < 1) {
        _contentError = '최소 1자 이상 입력해주세요';
      }
    });
  }

  void _clearErrors() {
    setState(() {
      _shouldShowErrors = false;
      _contentError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 내용이 입력되면 에러 제거
    final content = widget.viewModel.contentController.text.trim();
    if (content.isNotEmpty && content.length >= 1 && _contentError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _contentError = null;
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
          // 상세 내용 카드
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
          if (_shouldShowErrors && _contentError != null)
            Padding(
              padding: EdgeInsets.only(top: context.spacingSmall),
              child: Text(
                _contentError!,
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

