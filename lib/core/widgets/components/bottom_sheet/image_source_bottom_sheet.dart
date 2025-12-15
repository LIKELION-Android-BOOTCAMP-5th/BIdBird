import 'package:flutter/material.dart';

class ImageSourceBottomSheet extends StatelessWidget {
  const ImageSourceBottomSheet({
    super.key,
    required this.onGalleryTap,
    required this.onCameraTap,
    this.onVideoTap,
    this.onDeleteTap,
  });

  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;
  final VoidCallback? onVideoTap;
  final VoidCallback? onDeleteTap;

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
          if (onVideoTap != null)
            _ImageSourceActionItem(
              icon: Icons.videocam_outlined,
              label: '동영상 선택',
              onTap: () {
                Navigator.of(context).pop();
                onVideoTap!();
              },
            ),
          if (onDeleteTap != null)
            _ImageSourceActionItem(
              icon: Icons.delete_outline,
              label: '사진 삭제',
              onTap: () {
                Navigator.of(context).pop();
                onDeleteTap!();
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
    VoidCallback? onVideoTap,
    VoidCallback? onDeleteTap,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ImageSourceBottomSheet(
        onGalleryTap: onGalleryTap,
        onCameraTap: onCameraTap,
        onVideoTap: onVideoTap,
        onDeleteTap: onDeleteTap,
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
                Icon(widget.icon, size: 24, color: const Color(0xFF9CA3AF)),
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
