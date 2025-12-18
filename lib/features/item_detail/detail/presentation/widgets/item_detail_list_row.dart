import 'package:flutter/material.dart';

class ItemDetailListRow extends StatelessWidget {
  const ItemDetailListRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    super.key,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              // 좌: 아이콘 영역 40
              SizedBox(
                width: 40,
                height: 40,
                child: icon,
              ),
              const SizedBox(width: 12),
              // 중앙: 텍스트 스택
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF191F28), // Primary Text
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7684), // Secondary
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 우: chevron
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF9CA3AF), // Tertiary
              ),
            ],
          ),
        ),
      ),
    );
  }
}

