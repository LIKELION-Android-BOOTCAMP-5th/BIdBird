import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 거래 액션 바텀시트
class TradeActionBottomSheet extends StatelessWidget {
  const TradeActionBottomSheet({
    super.key,
    required this.onTradeComplete,
    this.onTradeCancel,
    this.isTradeCompleted = false,
  });

  final VoidCallback onTradeComplete;
  final VoidCallback? onTradeCancel;
  final bool isTradeCompleted;

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
          if (!isTradeCompleted)
            _TradeActionItem(
              label: '거래 완료',
              icon: Icons.check_circle_outline,
              onTap: () {
                Navigator.of(context).pop();
                onTradeComplete();
              },
            ),
          if (onTradeCancel != null && !isTradeCompleted)
            _TradeActionItem(
              label: '거래 취소',
              icon: Icons.cancel_outlined,
              textColor: RedColor,
              iconColor: RedColor,
              onTap: () {
                Navigator.of(context).pop();
                onTradeCancel!();
              },
            ),
          _TradeActionItem(
            label: '닫기',
            icon: Icons.close,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 바텀시트를 표시하는 헬퍼 메서드
  static void show(
    BuildContext context, {
    required VoidCallback onTradeComplete,
    VoidCallback? onTradeCancel,
    bool isTradeCompleted = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => TradeActionBottomSheet(
        onTradeComplete: onTradeComplete,
        onTradeCancel: onTradeCancel,
        isTradeCompleted: isTradeCompleted,
      ),
    );
  }
}

class _TradeActionItem extends StatefulWidget {
  const _TradeActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  State<_TradeActionItem> createState() => _TradeActionItemState();
}

class _TradeActionItemState extends State<_TradeActionItem>
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
                Icon(
                  widget.icon,
                  size: 24,
                  color: widget.iconColor ?? const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 14),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: widget.textColor ?? const Color(0xFF111827),
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

