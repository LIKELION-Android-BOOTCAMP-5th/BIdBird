import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:bidbird/core/utils/ui_set/icons.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/ui_set/border_radius.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('프로필'),
            Image.asset(
              'assets/icons/alarm_icon.png',
              width: iconSize.width,
              height: iconSize.height,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Expanded(
            child: GestureDetector(
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AskPopup(
                      content: '로그아웃 하시겠습니까?',
                      yesText: '확인',
                      noText: '취소',
                      yesLogic: () async {
                        Navigator.pop(dialogContext);
                        await context.read<AuthViewModel>().logout(
                          onLoggedOut: () {
                            context.go('/login');
                          },
                        );
                      },
                    );
                  },
                );
              },
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: defaultBorder,
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: buttonFontStyle.fontSize,
                    fontWeight: buttonFontStyle.fontWeight,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
