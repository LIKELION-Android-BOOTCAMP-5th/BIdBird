import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/report_category_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/report_reason_bottom_sheet.dart';
import 'package:bidbird/features/report/presentation/viewmodels/report_viewmodel.dart';
import 'package:flutter/material.dart';

class ReportReasonSection extends StatelessWidget {
  const ReportReasonSection({
    super.key,
    required this.viewModel,
  });

  final ReportViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F5BFF);
    const Color cardBackground = Color(0xFFFFFFFF);
    const Color borderGray = Color(0xFFE6E8EB);
    const Color textPrimary = Color(0xFF111111);
    const Color textSecondary = Color(0xFF6B7280);
    const Color textDisabled = Color(0xFF9CA3AF);
    const Color errorColor = Color(0xFFE5484D);

    final vm = viewModel;

    // 로딩 상태 또는 에러 상태 처리
    if (vm.categories.isEmpty && !vm.isLoading) {
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
          children: [
            const Text(
              '신고 사유를 불러올 수 없습니다.',
              style: TextStyle(color: errorColor),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 4),
              Text(
                vm.error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => vm.loadReportTypes(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (vm.categories.isEmpty && vm.isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: defaultBorder,
          border: Border.all(
            color: borderGray,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '신고 사유를 불러오는 중...',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      );
    }

    String? getCategoryDisplayName() {
      if (vm.selectedCategory == null) return null;
      try {
        final firstType = vm.allReportTypes
            .firstWhere((e) => e.category == vm.selectedCategory);
        return firstType.categoryName;
      } catch (e) {
        return vm.selectedCategory;
      }
    }

    String? getReasonDisplayName() {
      if (vm.selectedReportCode == null) return null;
      try {
        final type = vm.allReportTypes
            .firstWhere((e) => e.reportType == vm.selectedReportCode);
        return type.description;
      } catch (e) {
        return vm.selectedReportCode;
      }
    }

    final labelFontSize = context.fontSizeMedium;
    final spacing = context.spacingMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 대분류 선택
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: context.labelBottomPadding),
              child: Row(
                children: [
                  Text(
                    '신고 사유',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ReportCategoryBottomSheet.show(
                  context,
                  categories: vm.categories,
                  allReportTypes: vm.allReportTypes,
                  selectedCategory: vm.selectedCategory,
                  onCategorySelected: (category) {
                    vm.selectCategory(category);
                  },
                );
              },
              child: Container(
                height: 48,
                padding: EdgeInsets.symmetric(
                  horizontal: context.inputPadding,
                ),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(defaultRadius),
                  border: Border.all(
                    color: vm.selectedCategory != null ? blueColor : BackgroundColor,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          getCategoryDisplayName() ?? '신고 사유를 선택하세요',
                          style: TextStyle(
                            fontSize: context.fontSizeSmall,
                            color: vm.selectedCategory != null
                                ? textColor
                                : iconColor,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: vm.selectedCategory != null ? blueColor : iconColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 소분류 선택
        SizedBox(height: spacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: context.labelBottomPadding),
              child: Row(
                children: [
                  Text(
                    '상세 사유',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: vm.selectedCategory == null
                  ? null
                  : () {
                      ReportReasonBottomSheet.show(
                        context,
                        reportTypes: vm.selectedCategoryReports,
                        selectedReportCode: vm.selectedReportCode,
                        onReasonSelected: (reportCode) {
                          vm.selectReportCode(reportCode);
                        },
                      );
                    },
              child: Container(
                height: 48,
                padding: EdgeInsets.symmetric(
                  horizontal: context.inputPadding,
                ),
                decoration: BoxDecoration(
                  color: vm.selectedCategory == null
                      ? BorderColor.withValues(alpha: 0.2)
                      : cardBackground,
                  borderRadius: BorderRadius.circular(defaultRadius),
                  border: Border.all(
                    color: vm.selectedReportCode != null ? blueColor : BackgroundColor,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          getReasonDisplayName() ??
                              (vm.selectedCategory == null
                                  ? '대분류를 먼저 선택해주세요'
                                  : '신고 사유를 선택하세요'),
                          style: TextStyle(
                            fontSize: context.fontSizeSmall,
                            color: vm.selectedReportCode != null
                                ? textColor
                                : iconColor,
                          ),
                        ),
                      ),
                    ),
                    if (vm.selectedCategory != null)
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: vm.selectedReportCode != null
                            ? blueColor
                            : iconColor,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}



