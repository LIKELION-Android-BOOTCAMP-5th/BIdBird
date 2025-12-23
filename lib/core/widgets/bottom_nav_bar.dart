import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chat_list_viewmodel.dart';
import 'package:bidbird/features/current_trade/presentation/viewmodels/current_trade_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../utils/ui_set/colors_style.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/home')) currentIndex = 0;
    if (location.startsWith('/bid')) currentIndex = 1;
    if (location.startsWith('/chat')) currentIndex = 2;
    if (location.startsWith('/mypage')) currentIndex = 3;

    return BottomNavigationBar(
      // showSelectedLabels: false,
      // showUnselectedLabels: false,
      backgroundColor: Colors.white,
      unselectedItemColor: iconColor,
      currentIndex: currentIndex,
      selectedLabelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
      selectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/bid');
            break;
          case 2:
            context.go('/chat');
            break;
          case 3:
            context.go('/mypage');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/icons/home_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          activeIcon: Image.asset(
            'assets/icons/home_select_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: _TradeBadgeIcon(
            assetPath: 'assets/icons/bid_icon.png',
          ),
          activeIcon: _TradeBadgeIcon(
            assetPath: 'assets/icons/bid_select_icon.png',
          ),
          label: '현재 거래',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              Image.asset(
                'assets/icons/chat_icon.png',
                width: iconSize.width,
                height: iconSize.height,
              ),
              Selector<ChatListViewmodel, int>(
                selector: (_, vm) => vm.totalUnreadCount,
                builder: (_, count, __) {
                  return Badge(
                    isLabelVisible: count > 0, // 0보다 클 때만 표시
                    backgroundColor: Colors.red,
                    smallSize: 8, // 작은 점 형태의 배지 크기
                    // offset을 통해 위치를 미세하게 조정할 수 있습니다 (가로, 세로)
                    label: null,
                    alignment: const AlignmentDirectional(
                      1.2,
                      -1.2,
                    ), // 좌표 기반 위치 조정
                    child: Image.asset(
                      'assets/icons/chat_icon.png', // 아이콘이 active일 때와 아닐 때 분기 처리 필요
                      width: iconSize.width,
                      height: iconSize.height,
                    ),
                  );
                },
              ),
            ],
          ),

          activeIcon: Stack(
            children: [
              Image.asset(
                'assets/icons/chat_select_icon.png',
                width: iconSize.width,
                height: iconSize.height,
              ),
              Selector<ChatListViewmodel, int>(
                selector: (_, vm) => vm.totalUnreadCount,
                builder: (_, count, __) {
                  return Badge(
                    isLabelVisible: count > 0, // 0보다 클 때만 표시
                    backgroundColor: Colors.red,
                    smallSize: 8, // 작은 점 형태의 배지 크기
                    // offset을 통해 위치를 미세하게 조정할 수 있습니다 (가로, 세로)
                    label: null,
                    alignment: const AlignmentDirectional(
                      1.2,
                      -1.2,
                    ), // 좌표 기반 위치 조정
                    child: Image.asset(
                      'assets/icons/chat_select_icon.png', // 아이콘이 active일 때와 아닐 때 분기 처리 필요
                      width: iconSize.width,
                      height: iconSize.height,
                    ),
                  );
                },
              ),
            ],
          ),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/icons/profile_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          activeIcon: Image.asset(
            'assets/icons/profile_select_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          label: '마이페이지',
        ),
      ],
    );
  }
}

class _TradeBadgeIcon extends StatelessWidget {
  const _TradeBadgeIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Selector<CurrentTradeViewModel, bool>(
      selector: (_, vm) => vm.hasPendingTradeAction,
      builder: (_, hasPending, __) {
        return Badge(
          isLabelVisible: hasPending,
          backgroundColor: Colors.red,
          smallSize: 8,
          alignment: const AlignmentDirectional(1.2, -1.2),
          label: null,
          child: Image.asset(
            assetPath,
            width: iconSize.width,
            height: iconSize.height,
          ),
        );
      },
    );
  }
}
