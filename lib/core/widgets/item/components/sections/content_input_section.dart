import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/fields/error_text.dart';
import 'package:bidbird/core/widgets/item/components/fields/form_label.dart';
import 'package:flutter/material.dart';

/// 신고하기와 매물 등록에서 공통으로 사용
class ContentInputSection extends StatefulWidget {
  const ContentInputSection({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLength = 500,
    this.minLength,
    this.minLines,
    this.maxLines,
    this.successMessage,
    this.errorMessage,
  });

  /// 섹션 제목
  final String label;

  /// 텍스트 컨트롤러
  final TextEditingController controller;

  /// 힌트 텍스트
  final String hintText;

  /// 최대 글자 수
  final int maxLength;

  /// 최소 글자 수 (null이면 검증 안 함)
  final int? minLength;

  /// 최소 줄 수 (null이면 제한 없음)
  final int? minLines;

  /// 최대 줄 수 (null이면 제한 없음)
  final int? maxLines;

  /// 최소 글자 수 충족 시 표시할 메시지
  final String? successMessage;

  /// 최소 글자 수 미충족 시 표시할 에러 메시지
  final String? errorMessage;

  @override
  State<ContentInputSection> createState() => _ContentInputSectionState();
}

class _ContentInputSectionState extends State<ContentInputSection> {
  static const double _cardPadding = 14.0;
  static const double _labelBottomSpacing = 12.0;
  static const double _counterTopSpacing = 8.0;

  Widget _buildTextField() {
    final isExpandable = widget.minLines == null && widget.maxLines == null;
    
    final textField = TextField(
      controller: widget.controller,
      maxLines: isExpandable ? null : widget.maxLines,
      minLines: isExpandable ? null : widget.minLines,
      maxLength: widget.maxLength,
      cursorColor: PrimaryBlue,
      style: const TextStyle(
        color: TextPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: chatTimeTextColor,
          fontSize: context.fontSizeSmall,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        counterText: '',
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
      onChanged: (_) => setState(() {}),
    );

    return isExpandable ? Expanded(child: textField) : textField;
  }

  @override
  Widget build(BuildContext context) {
    final textLength = widget.controller.text.length;
    final isValid = widget.minLength == null || textLength >= widget.minLength!;
    final showValidation = widget.minLength != null;

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(_cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          border: Border.all(
            color: LightBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            FormLabel(text: widget.label),
            SizedBox(height: _labelBottomSpacing),
            _buildTextField(),
            SizedBox(height: _counterTopSpacing),
            Row(
              mainAxisAlignment: showValidation && widget.successMessage != null && isValid
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (showValidation && widget.successMessage != null && isValid)
                  Text(
                    widget.successMessage!,
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      color: TextSecondary,
                    ),
                  ),
                Text(
                  '$textLength/${widget.maxLength}',
                  style: TextStyle(
                    fontSize: context.fontSizeSmall,
                    color: chatTimeTextColor,
                  ),
                ),
              ],
            ),
            if (widget.errorMessage != null)
              ErrorText(
                text: widget.errorMessage!,
                topPadding: _counterTopSpacing,
              ),
          ],
        ),
      ),
    );
  }
}
