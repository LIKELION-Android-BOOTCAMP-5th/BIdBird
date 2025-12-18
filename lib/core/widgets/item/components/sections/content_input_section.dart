import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
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
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F5BFF);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textPrimary = Color(0xFF111111);
    const Color textSecondary = Color(0xFF6B7280);
    const Color textDisabled = Color(0xFF9CA3AF);
    final textLength = widget.controller.text.length;
    final isValid = widget.minLength == null || textLength >= widget.minLength!;
    final showValidation = widget.minLength != null;

    return Container(
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
            widget.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          widget.minLines == null && widget.maxLines == null
              ? Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLines: null,
                    minLines: null,
                    maxLength: widget.maxLength,
                    cursorColor: primaryBlue,
                    style: const TextStyle(
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
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
                )
              : TextField(
                  controller: widget.controller,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  maxLength: widget.maxLength,
                  cursorColor: primaryBlue,
                  style: const TextStyle(
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
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
            mainAxisAlignment: showValidation && widget.successMessage != null && isValid
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (showValidation && widget.successMessage != null && isValid)
                Text(
                  widget.successMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              Text(
                '$textLength/${widget.maxLength}',
                style: const TextStyle(
                  fontSize: 12,
                  color: textDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
