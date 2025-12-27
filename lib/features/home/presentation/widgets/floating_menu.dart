import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bidbird/core/managers/nhost_manager.dart';
import '../../../../core/utils/ui_set/colors_style.dart';
import 'floating_item.dart';

class FloatingMenu extends StatefulWidget {
  const FloatingMenu({super.key});

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> {
  bool _open = false;

  Future<void> _verifiedPush(String route) async {
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_open)
          Positioned(
            bottom: 90,
            right: 16,
            child: Column(
              children: [
                FabMenuItem(
                  label: "매물 작성",
                  icon: Icons.edit_outlined,
                  onTap: () async {
                    setState(() => _open = false);
                    if (!NhostManager.shared.isInitialized) {
                      await NhostManager.shared.initialize();
                    }
                    _verifiedPush('/add_item');
                  },
                ),
                const SizedBox(height: 12),
                FabMenuItem(
                  label: "매물 등록",
                  icon: Icons.check_circle_outline,
                  onTap: () async {
                    setState(() => _open = false);
                    if (!NhostManager.shared.isInitialized) {
                      await NhostManager.shared.initialize();
                    }
                    _verifiedPush('/add_item/item_registration_list');
                  },
                ),
              ],
            ),
          ),

        // FAB 버튼 (Requirement 8 & 9: Static but opaque)
        Positioned(
          bottom: 16,
          right: 16,
          child: Transform.scale(
            scale: 0.9,
            child: FloatingActionButton(
              shape: const CircleBorder(),
              backgroundColor: blueColor,
              onPressed: () => setState(() => _open = !_open),
              child: Icon(_open ? Icons.close : Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
