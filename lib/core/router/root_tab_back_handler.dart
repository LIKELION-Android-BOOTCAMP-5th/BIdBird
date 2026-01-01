import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

class RootTabBackHandler extends StatelessWidget {
  final Widget child;
  final bool isHome;

  const RootTabBackHandler({
    super.key,
    required this.child,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 시스템 팝 방지
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. 현재 탭 안에서 뒤로 갈 페이지가 있는지 확인
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // 2. 탭의 첫 페이지라면
          if (!isHome) {
            // 홈 탭이 아니면 홈으로 강제 이동
            StatefulNavigationShell.of(context).goBranch(0);
          } else {
            // 홈 탭의 첫 페이지면 토스트 출력
            doubleBackHandler.onWillPop(context);
          }
        }
      },
      child: child,
    );
  }
}
