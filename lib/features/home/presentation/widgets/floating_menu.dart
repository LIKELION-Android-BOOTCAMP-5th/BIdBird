import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/ui_set/colors_style.dart';
import '../../../identity_verification/presentation/utils/identity_verification_helper.dart';
import 'floating_item.dart';

class FloatingMenu extends StatefulWidget {
  const FloatingMenu({super.key});

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> {
  bool _open = false;

  Future<void> _verifiedPush(String route) async {
    // TODO: 사업자 인증 후 아래 주석 해제
    // final verified = await ensureIdentityVerified(context);
    // if (!verified) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 펼쳐진 메뉴
        if (_open)
          Positioned(
            bottom: 90,
            right: 16,
            child: Column(
              children: [
                FabMenuItem(
                  label: "매물 작성",
                  icon: Icons.edit_outlined,
                  onTap: () {
                    setState(() => _open = false);
                    _verifiedPush('/add_item');
                  },
                ),
                const SizedBox(height: 12),
                FabMenuItem(
                  label: "매물 등록",
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    setState(() => _open = false);
                    _verifiedPush('/add_item/item_registration_list');
                  },
                ),
              ],
            ),
          ),

        // FAB 버튼
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: blueColor,
            onPressed: () => setState(() => _open = !_open),
            child: Icon(_open ? Icons.close : Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
