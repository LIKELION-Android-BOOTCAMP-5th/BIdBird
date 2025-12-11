import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_entity.dart';

class SupabaseManager {
  static final SupabaseManager _shared = SupabaseManager();

  static SupabaseManager get shared => _shared;

  // Get a reference your Supabase client
  final supabase = Supabase.instance.client;

  // 생성자
  SupabaseManager() {
    debugPrint("SupabaseManager init");
  }

  String getAuthorizationKey() {
    String authorizationKey = supabase.auth.currentSession?.accessToken != null
        ? 'Bearer ${supabase.auth.currentSession?.accessToken}'
        : 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5ZmdmaWNjZWpqZ3R2cG10a3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNTUwNjksImV4cCI6MjA3NzYzMTA2OX0.Ng9atODZnfRocZPtnIb74s6PLeIJ2HqqSaatj1HbRsc';
    return authorizationKey;
  }

  Future<void> googleSignIn() async {
    const webClientId =
        '966757848850-cscnd3oli3ts6c8e6ch6p1ev485b9ej5.apps.googleusercontent.com';

    const iosClientId =
        '966757848850-1cj4f09hqn0nlfk1e2l3i0rbs82gqtos.apps.googleusercontent.com';

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
