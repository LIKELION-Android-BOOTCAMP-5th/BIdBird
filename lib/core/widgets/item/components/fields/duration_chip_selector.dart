import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

/// 경매 기간 선택 칩 위젯
/// 4개씩 2줄로 배치되는 칩 선택 UI
class DurationChipSelector extends StatelessWidget {
  const DurationChipSelector({
    super.key,
    required this.durations,
    required this.selectedDuration,
    required this.onDurationSelected,
    this.onErrorCleared,
  });

  /// 선택 가능한 경매 기간 목록
  final List<String> durations;

  /// 현재 선택된 경매 기간
  final String? selectedDuration;

  /// 경매 기간 선택 콜백
  final ValueChanged<String> onDurationSelected;

  /// 에러 제거 콜백 (선택 사항)
  final VoidCallback? onErrorCleared;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final spacing = context.spacingSmall;
        final chipWidth = (availableWidth - (spacing * 3)) / 4; // 4개 배치: 간격 3개
        
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: durations.map((duration) {
            final isSelected = selectedDuration == duration;
            return SizedBox(
              width: chipWidth,
              child: GestureDetector(
                onTap: () {
                  onDurationSelected(duration);
                  onErrorCleared?.call();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.inputPadding,
                    vertical: context.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? blueColor.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(defaultRadius),
                    border: Border.all(
                      color: isSelected ? blueColor : BackgroundColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    duration,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      color: isSelected ? blueColor : textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}



