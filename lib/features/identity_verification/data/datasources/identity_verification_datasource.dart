import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/identity_verification/presentation/screens/identity_verification_webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IdentityVerificationDatasource {
  IdentityVerificationDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<bool> hasCi() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final userEntity = await SupabaseManager.shared.fetchUser(user.id);
      final ci = userEntity?.CI;
      return ci != null && ci.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getImpUidFromWebView(BuildContext context) async {
    final impUid = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const KgInicisIdentityWebViewScreen(),
      ),
    );

    if (impUid == null ||
        impUid.isEmpty ||
        !impUid.startsWith('imp_') ||
        impUid.length < 10 ||
        impUid.length > 100) {
      return null;
    }

    return impUid;
  }

  Future<bool> submitIdentityVerification(String impUid) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final response = await _supabase.functions.invoke(
        'identity',
        body: {
          'imp_uid': impUid,
          'user_id': user.id,
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}



