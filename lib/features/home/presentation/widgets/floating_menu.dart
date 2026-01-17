import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/ui_set/colors_style.dart';
import 'floating_item.dart';

class FloatingMenu extends StatefulWidget {
  final GlobalKey? fabKey; // 1. 키를 받을 변수 추가

  const FloatingMenu({super.key, this.fabKey}); // 2. 생성자에 추가

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> {
  Future<void> _verifiedPush(String route) async {
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Transform.scale(
        scale: 0.9,
        child: FloatingActionButton(
          key: widget.fabKey,
          shape: const CircleBorder(),
          backgroundColor: blueColor,
          onPressed: () async {
             _verifiedPush('/add_item');
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
