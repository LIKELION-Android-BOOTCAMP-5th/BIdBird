import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/logos/bidbird_image_text_logo.png',
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
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
                      child: Text(
                        'Google 계정으로 계속하기',
                        style: titleFontStyle.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
