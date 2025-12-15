import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 거래 취소 사유 선택 바텀시트
class TradeCancelReasonBottomSheet extends StatelessWidget {
  const TradeCancelReasonBottomSheet({
    super.key,
    required this.onReasonSelected,
  });

  final ValueChanged<String> onReasonSelected;

  static const List<Map<String, String>> _cancelReasons = [
    {'code': 'contact_failed', 'label': '연락 불가'},
    {'code': 'condition_mismatch', 'label': '조건 불일치'},
    {'code': 'personal_reason', 'label': '개인 사정'},
    {'code': 'other', 'label': '기타'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text(
                  '취소 사유를 선택해주세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          ..._cancelReasons.map((reason) {
            return _CancelReasonItem(
              label: reason['label']!,
              onTap: () {
                Navigator.of(context).pop();
                onReasonSelected(reason['code']!);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 바텀시트를 표시하는 헬퍼 메서드
  static void show(
    BuildContext context, {
    required ValueChanged<String> onReasonSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => TradeCancelReasonBottomSheet(
        onReasonSelected: onReasonSelected,
      ),
    );
  }
}

class _CancelReasonItem extends StatefulWidget {
  const _CancelReasonItem({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_CancelReasonItem> createState() => _CancelReasonItemState();
}

class _CancelReasonItemState extends State<_CancelReasonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: const Color(0xFFFAFAFB),
      end: const Color(0xFFF3F4F6),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            height: 56,
            padding: const EdgeInsets.only(left: 20),
            color: _colorAnimation.value,
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111827),
                    letterSpacing: -0.15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


