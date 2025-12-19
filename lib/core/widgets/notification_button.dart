import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/features/notification/presentation/viewmodel/notification_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/notifications');
      },
      child: Stack(
        children: [
          Image.asset(
            'assets/icons/alarm_icon.png',
            width: iconSize.width,
            height: iconSize.height,
          ),
          Selector<NotificationViewmodel, int>(
            selector: (_, vm) => vm.unCheckedCount,
            builder: (_, count, __) {
              return count > 0
                  ? Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: blueColor, // 파란색 (원하면 변경)
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : Container();
            },
          ),
        ],
      ),
    );
  }
}
