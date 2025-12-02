import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/user_entity.dart';

class SupabaseManager {
  // 이유 - 밖에서 shared를 null등 건드리지 못하게
  // 오 일단 생성이 되었다.
  static final SupabaseManager _shared = SupabaseManager();

  static SupabaseManager get shared => _shared;

  // Get a reference your Supabase client
  final supabase = Supabase.instance.client;

  // 생성자
  SupabaseManager() {
    debugPrint("SupabaseManager init");
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
