import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                  SizedBox(
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffF2F2F2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.7),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        try {
                          if (!kIsWeb &&
                              (Platform.isAndroid || Platform.isIOS)) {
                            await SupabaseManager.shared.googleSignIn();
                          } else {
                            await SupabaseManager.shared.supabase.auth
                                .signInWithOAuth(OAuthProvider.google);
                          }
                        } catch (e) {
                          return;
                        }
                      },
                      child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logos/google_logo.png'),
                            Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                color: Color(0xff1F1F1F),
                                fontFamily: 'GoogleFont',
                              ),
                            ),
                            SizedBox(
                              width: context.widthRatio(
                                0.025,
                                min: 8.0,
                                max: 14.0,
                              ),
                            ), // 특수 케이스: 버튼 내부 간격
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: spacing),

                  SizedBox(
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.7),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        SupabaseManager.shared.signInWithApple();
                      },
                      child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logos/apple_logo.png'),
                            Text(
                              'Sign in with Apple',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                color: Colors.white,
                                fontFamily: 'GoogleFont',
                              ),
                            ),
                            SizedBox(width: context.inputPadding),
                          ],
                        ),
                      ),
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

