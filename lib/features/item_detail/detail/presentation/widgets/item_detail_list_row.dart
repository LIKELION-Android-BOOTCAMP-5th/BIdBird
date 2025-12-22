import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

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
    final rowHeight = context.heightRatio(0.07, min: 52.0, max: 68.0);
    final iconSize = context.widthRatio(0.11, min: 38.0, max: 48.0);
    final horizontalSpacing = context.spacingSmall;
    final titleFont = TextStyle(
      fontSize: context.fontSizeMedium,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF191F28),
    );
    final subtitleFont = TextStyle(
      fontSize: context.fontSizeSmall,
      color: const Color(0xFF6B7684),
    );
    final chevronSize = context.iconSizeSmall;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: rowHeight,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              // 좌: 아이콘 영역 40
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: icon,
              ),
              SizedBox(width: horizontalSpacing),
              // 중앙: 텍스트 스택
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleFont,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: horizontalSpacing * 0.45),
                      Text(
                        subtitle!,
                        style: subtitleFont,
                      ),
                    ],
                  ],
                ),
              ),
              // 우: chevron
              Icon(
                Icons.chevron_right,
                size: chevronSize,
                color: const Color(0xFF9CA3AF), // Tertiary
              ),
            ],
          ),
        ),
      ),
    );
  }
}

