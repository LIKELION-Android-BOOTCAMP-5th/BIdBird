import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      showSelectedLabels: false,
      showUnselectedLabels: false,
      backgroundColor: Colors.white,
      unselectedItemColor: iconColor,
      currentIndex: currentIndex,
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
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/icons/bid_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          activeIcon: Image.asset(
            'assets/icons/bid_select_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/icons/chat_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          activeIcon: Image.asset(
            'assets/icons/chat_select_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          label: '',
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
          label: '',
        ),
      ],
    );
  }
}
