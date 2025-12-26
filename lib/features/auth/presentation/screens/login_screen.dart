import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widget/login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final horizontalPadding = context.hPadding;
    final logoHeight = context.heightRatio(
      0.3,
      min: 412.0,
      max: 512.0,
    ); // 특수 케이스: 로고 높이
    final buttonHeight = context.buttonHeight;
    final buttonFontSize = context.buttonFontSize;
    final spacing = context.spacingSmall;
    final logoSpacing = context.spacingSmall * 0.5;

    return WillPopScope(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/logos/bidbird_image_text_logo.png',
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: logoSpacing),
                  LoginButton(
                    buttonHeight: buttonHeight,
                    buttonFontSize: buttonFontSize,
                    buttonLogic: () async {
                      try {
                        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                          await SupabaseManager.shared.googleSignIn();
                        } else {
                          await SupabaseManager.shared.supabase.auth
                              .signInWithOAuth(OAuthProvider.google);
                        }
                      } catch (e) {
                        return;
                      }
                    },
                    logoImage: 'assets/logos/google_logo.png',
                    buttonText: '구글 로그인',
                    backgroundColor: Color(0xffF2F2F2),
                    textColor: Color(0xff1F1F1F),
                  ),

                  SizedBox(height: spacing),

                  SizedBox(
                    height: buttonHeight,
                    child: LoginButton(
                      buttonHeight: buttonHeight,
                      buttonFontSize: buttonFontSize,
                      buttonLogic: SupabaseManager.shared.signInWithApple,
                      logoImage: 'assets/logos/apple_logo.png',
                      buttonText: '애플 로그인',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: spacing),

                  SizedBox(
                    height: buttonHeight,
                    child: LoginButton(
                      buttonHeight: buttonHeight,
                      buttonFontSize: buttonFontSize,
                      buttonLogic: SupabaseManager.shared.signInWithKakao,
                      logoImage: 'assets/logos/kakao_logo.png',
                      buttonText: '카카오 로그인',
                      backgroundColor: Color(0xffFEE500),
                      textColor: Color(0xff000000),
                    ),
                  ),

                  SizedBox(height: spacing * 1.5),
                ],
              ),
            ),
          ),
        ),
      ),
      onWillPop: () async {
        context.go('/home');
        return false;
      },
    );
  }
}

// SizedBox(
// height: buttonHeight,
// child: ElevatedButton(
// style: ElevatedButton.styleFrom(
// backgroundColor: Colors.black,
// foregroundColor: Colors.white,
// shape: RoundedRectangleBorder(
// borderRadius: BorderRadius.circular(8.7),
// ),
// elevation: 0,
// ),
// onPressed: () {
// SupabaseManager.shared.signInWithApple();
// },
// child: Align(
// alignment: Alignment.center,
// child: Row(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// Image.asset('assets/logos/apple_logo.png'),
// Text(
// '애플 아이디로 로그인',
// style: TextStyle(
// fontSize: buttonFontSize,
// color: Colors.white,
// fontFamily: 'GoogleFont',
// ),
// ),
// SizedBox(width: context.inputPadding),
// ],
// ),
// ),
// ),
// ),
