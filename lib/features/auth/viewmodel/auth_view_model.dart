import 'package:bidbird/core/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;

  Future<void> signInWithGoogle(BuildContext context) async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '966757848850-cscnd3oli3ts6c8e6ch6p1ev485b9ej5.apps.googleusercontent.com',
        
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('구글 인증 토큰을 가져오지 못했습니다.');
      }

      final res = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (res.user != null) {
        if (context.mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해 주세요.')),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
