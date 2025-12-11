import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
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
        backgroundColor: Colors.white,
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
                    height: 56,
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
                                fontSize: 24,
                                color: Color(0xff1F1F1F),
                                fontFamily: 'GoogleFont',
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 56,
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
                                fontSize: 24,
                                color: Colors.white,
                                fontFamily: 'GoogleFont',
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
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
