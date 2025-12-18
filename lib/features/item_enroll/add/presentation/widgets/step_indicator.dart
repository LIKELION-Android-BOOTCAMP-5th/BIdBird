import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

/// 스텝 인디케이터 위젯
/// 상단에 고정되어 현재 단계를 표시합니다.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  /// 현재 단계 (0부터 시작)
  final int currentStep;

  /// 전체 단계 수
  final int totalSteps;

  /// 각 단계의 라벨
  final List<String> stepLabels;

  static const double _circleSize = 32;
  static const double _lineHeight = 2;
  static const double _gap = 16;
  static const double _lineWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.hPadding,
        vertical: context.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: shadowLow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildChildren(context),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final List<Widget> children = [];

    for (int index = 0; index < totalSteps; index++) {
      final bool isActive = index == currentStep;
      final bool isCompleted = index < currentStep;
      final bool isLast = index == totalSteps - 1;

      final Color circleColor = (isActive || isCompleted)
          ? blueColor
          : BorderColor.withValues(alpha: 0.3);

      final Color connectorColor = isCompleted
          ? blueColor
          : BorderColor.withValues(alpha: 0.3);

      final Color labelColor = isActive
          ? blueColor
          : isCompleted
              ? textColor
              : iconColor;

      // 스텝(원 + 라벨) - Flexible로 공간 균등 분배
      children.add(
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      )
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color:
                              (isActive || isCompleted) ? Colors.white : iconColor,
                          fontSize: context.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                stepLabels[index],
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fontSizeSmall * 0.9,
                  color: labelColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );

      // 선(원 중앙 높이에 정렬) - 고정 너비
      if (!isLast) {
        children.add(
          Container(
            width: _lineWidth,
            height: _circleSize,
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: _gap),
            child: Container(
              width: _lineWidth,
              height: _lineHeight,
              decoration: BoxDecoration(
                color: connectorColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      }
    }

    return children;
  }
}

