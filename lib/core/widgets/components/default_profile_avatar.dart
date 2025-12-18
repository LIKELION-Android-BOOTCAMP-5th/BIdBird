import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 기본 프로필 아바타 위젯
/// 프로필 이미지가 없을 때 사용하는 기본 프로필 아이콘
class DefaultProfileAvatar extends StatelessWidget {
  const DefaultProfileAvatar({
    super.key,
    this.radius,
    this.size,
  });

  /// 반지름 (CircleAvatar의 radius)
  final double? radius;

  /// 크기 (width, height) - radius 대신 사용 가능
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: CircleAvatar(
          radius: size! / 2,
          backgroundColor: BorderColor,
          child: Icon(
            Icons.person,
            color: BackgroundColor,
            size: size! * 0.6,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius ?? 24,
      backgroundColor: BorderColor,
      child: Icon(
        Icons.person,
        color: BackgroundColor,
        size: (radius ?? 24) * 0.8,
      ),
    );
  }
}

