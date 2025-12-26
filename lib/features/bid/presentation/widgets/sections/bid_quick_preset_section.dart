import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 빠른 선택 프리셋 섹션
class BidQuickPresetSection extends StatelessWidget {
  final List<BidPresetAction> actions;
  final void Function(int) onAdjust;
  final VoidCallback onResetMin;

  const BidQuickPresetSection({
    super.key,
    required this.actions,
    required this.onAdjust,
    required this.onResetMin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final action in actions)
            _buildChip(
              action.label,
              action.type == BidPresetActionType.adjust
                  ? () => onAdjust(action.value)
                  : onResetMin,
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: const Color(0xFFF2F3F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        foregroundColor: textColor,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

/// 입찰 프리셋 액션
class BidPresetAction {
  final String label;
  final int value;
  final BidPresetActionType type;

  const BidPresetAction(this.label, this.value, this.type);
}

/// 입찰 프리셋 액션 타입
enum BidPresetActionType { adjust, reset }
