import 'package:flutter/material.dart';

/// 사진 추가를 위한 바텀 시트 컴포넌트
/// 
/// 세련된 디자인의 바텀 시트로, 갤러리에서 선택하거나 사진을 찍을 수 있는 옵션을 제공합니다.
class ImageSourceBottomSheet extends StatelessWidget {
  const ImageSourceBottomSheet({
    super.key,
    required this.onGalleryTap,
    required this.onCameraTap,
  });

  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 인디케이터
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          // 액션 항목들
          _ImageSourceActionItem(
            icon: Icons.photo_library_outlined,
            label: '갤러리에서 선택',
            onTap: () {
              Navigator.of(context).pop();
              onGalleryTap();
            },
          ),
          _ImageSourceActionItem(
            icon: Icons.camera_alt_outlined,
            label: '사진 찍기',
            onTap: () {
              Navigator.of(context).pop();
              onCameraTap();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 바텀 시트를 표시하는 헬퍼 메서드
  static void show(
    BuildContext context, {
    required VoidCallback onGalleryTap,
    required VoidCallback onCameraTap,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => ImageSourceBottomSheet(
        onGalleryTap: onGalleryTap,
        onCameraTap: onCameraTap,
      ),
    );
  }
}

class _ImageSourceActionItem extends StatefulWidget {
  const _ImageSourceActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ImageSourceActionItem> createState() => _ImageSourceActionItemState();
}

class _ImageSourceActionItemState extends State<_ImageSourceActionItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
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
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
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
                  color: const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 14),
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
