import 'package:flutter/material.dart';

class AuctionDurationBottomSheet extends StatelessWidget {
  const AuctionDurationBottomSheet({
    super.key,
    required this.durations,
    required this.selectedDuration,
    required this.onDurationSelected,
  });

  final List<String> durations;
  final String? selectedDuration;
  final ValueChanged<String> onDurationSelected;

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
          // 경매 기간 항목들 (스크롤 가능)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: durations.length,
              itemBuilder: (context, index) {
                final duration = durations[index];
                final isSelected = selectedDuration == duration;
                
                return _DurationItem(
                  label: duration,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.of(context).pop();
                    onDurationSelected(duration);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 바텀 시트를 표시하는 헬퍼 메서드
  static void show(
    BuildContext context, {
    required List<String> durations,
    String? selectedDuration,
    required ValueChanged<String> onDurationSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAFAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: AuctionDurationBottomSheet(
          durations: durations,
          selectedDuration: selectedDuration,
          onDurationSelected: onDurationSelected,
        ),
      ),
    );
  }
}

class _DurationItem extends StatefulWidget {
  const _DurationItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DurationItem> createState() => _DurationItemState();
}

class _DurationItemState extends State<_DurationItem>
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
      begin: widget.isSelected 
          ? const Color(0xFFF3F4F6) 
          : const Color(0xFFFAFAFB),
      end: const Color(0xFFF3F4F6),
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(_DurationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      _colorAnimation = ColorTween(
        begin: widget.isSelected 
            ? const Color(0xFFF3F4F6) 
            : const Color(0xFFFAFAFB),
        end: const Color(0xFFF3F4F6),
      ).animate(_controller);
    }
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
            color: widget.isSelected 
                ? const Color(0xFFF3F4F6) 
                : _colorAnimation.value,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111827),
                      letterSpacing: -0.15,
                    ),
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
