import 'dart:async';
import 'dart:convert';

import 'package:bidbird/core/config/firebase_config.dart';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_entity.dart';

class SupabaseManager {
  static final SupabaseManager _shared = SupabaseManager();

  static const String webRedirectUrl =
      'https://bidbird2025.github.io/bidbird2025/'; //일단여기에넣음

  static SupabaseManager get shared => _shared;

  // Get a reference your Supabase client
  final supabase = Supabase.instance.client;

  // 생성자
  SupabaseManager() {
    debugPrint("SupabaseManager init");
  }

  String getAuthorizationKey() {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception("토근이 없습니다");
    }
    return 'Bearer $token';
  }

  Future<void> googleSignIn() async {
    final webClientId = FirebaseConfig.googleWebClientId;
    final iosClientId = FirebaseConfig.googleIosClientId;

    final GoogleSignIn signIn = GoogleSignIn.instance;

    unawaited(
      signIn.initialize(clientId: iosClientId, serverClientId: webClientId),
    );

    // Perform the sign in
    final googleAccount = await signIn.authenticate();
    final googleAuthorization = await googleAccount.authorizationClient
        .authorizationForScopes(['email', 'profile']);
    final googleAuthentication = googleAccount.authentication;
    final idToken = googleAuthentication.idToken;
    final accessToken = googleAuthorization?.accessToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Performs Apple sign in on iOS or macOS
  Future<AuthResponse> signInWithApple() async {
    try {
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException(
          'Could not find ID Token from generated credential.',
        );
      }

      return supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('Apple Sign In Authorization 오류: ${e.code} - ${e.message}');

      // 에러 코드에 따른 처리
      if (e.code.toString().contains('1000') ||
          e.code.toString().contains('unknown')) {
        throw const AuthException(
          'Apple Sign In은 실제 기기에서만 사용할 수 있습니다. 시뮬레이터에서는 다른 로그인 방법을 사용해주세요.',
        );
      } else if (e.code.toString().contains('1001')) {
        // 사용자가 취소한 경우
        throw const AuthException('Apple 로그인이 취소되었습니다.');
      } else {
        throw AuthException('Apple 로그인 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      debugPrint('Apple Sign In 오류: $e');
      // 시뮬레이터나 개발 환경에서 발생하는 오류 처리
      if (e.toString().contains('1000') || e.toString().contains('unknown')) {
        throw const AuthException(
          'Apple Sign In은 실제 기기에서만 사용할 수 있습니다. 시뮬레이터에서는 다른 로그인 방법을 사용해주세요.',
        );
      }
      rethrow;
    }
  }

  Future<void> signInWithKakao() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: kIsWeb
          ? null
          : 'com.bidbird.app://oauth', // Optionally set the redirect link to bring back the user via deeplink.
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode
                .externalApplication, // Launch the auth screen in a new webview on mobile.
    );
  }

  Future<UserEntity?> fetchUser(String id) async {
    final List<Map<String, dynamic>> data = await supabase
        .from('users')
        .select()
        .eq('id', id);

    if (data.length == 0) return null;
    final List<UserEntity> results = data.map((json) {
      return UserEntity.fromJson(json);
    }).toList();
    return results.first;
  }
}
