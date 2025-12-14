import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/report/viewmodel/report_viewmodel.dart';
import 'package:flutter/material.dart';

class ReportContentSection extends StatefulWidget {
  const ReportContentSection({
    super.key,
    required this.viewModel,
  });

  final ReportViewModel viewModel;

  @override
  State<ReportContentSection> createState() => _ReportContentSectionState();
}

class _ReportContentSectionState extends State<ReportContentSection> {
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F5BFF);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textPrimary = Color(0xFF111111);
    const Color textSecondary = Color(0xFF6B7280);
    const Color textDisabled = Color(0xFF9CA3AF);
    const Color errorColor = Color(0xFFE5484D);

    final vm = widget.viewModel;

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
          const Text(
            '상세 내용',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vm.contentController,
            maxLines: 8,
            minLines: 6,
            maxLength: 500,
            cursorColor: primaryBlue,
            style: const TextStyle(
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '발생한 상황을 간단히 설명해주세요',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vm.contentController.text.length >= 10
                    ? '구체적으로 작성할수록 처리 속도가 빨라집니다'
                    : '10자 이상 입력해주세요',
                style: TextStyle(
                  fontSize: 12,
                  color: vm.contentController.text.length >= 10
                      ? textSecondary
                      : errorColor,
                ),
              ),
              Text(
                '${vm.contentController.text.length}/500',
                style: TextStyle(
                  fontSize: 12,
                  color: vm.contentController.text.length >= 10
                      ? textDisabled
                      : errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

