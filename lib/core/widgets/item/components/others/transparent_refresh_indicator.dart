import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 투명 배경의 파란색 RefreshIndicator 컴포넌트
/// 당겨서 새로고침 시 사용
class TransparentRefreshIndicator extends StatelessWidget {
  const TransparentRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        // Material의 overscroll 효과(회색 배경) 완전히 제거
        notification.disallowIndicator();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: Colors.white,
        backgroundColor: blueColor,
        displacement: 0,
        strokeWidth: 2.0,
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
