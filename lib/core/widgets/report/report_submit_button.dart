import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/report/viewmodel/report_viewmodel.dart';
import 'package:flutter/material.dart';

class ReportSubmitButton extends StatelessWidget {
  const ReportSubmitButton({
    super.key,
    required this.viewModel,
    required this.onSubmit,
  });

  final ReportViewModel viewModel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F5BFF);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color textDisabled = Color(0xFF9CA3AF);
    const Color buttonDisabledBg = Color(0xFFE5E7EB);

    final vm = viewModel;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: vm.canSubmit ? onSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            disabledBackgroundColor: buttonDisabledBg,
            foregroundColor: Colors.white,
            disabledForegroundColor: textDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            elevation: 0,
          ),
          child: const Text(
            '신고 제출',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

