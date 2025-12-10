import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/identity_verification/data/repository/identity_verification_gateway.dart';
import 'package:bidbird/features/item/identity_verification/screen/identity_verification_webview_screen.dart';
import 'package:flutter/material.dart';

class IdentityVerificationGatewayImpl implements IdentityVerificationGateway {
  IdentityVerificationGatewayImpl();

  @override
  Future<bool> hasCi() async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;

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

  @override
  Future<String> requestIdentityVerification(BuildContext context) async {
    final ci = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const KgInicisIdentityWebViewScreen(),
      ),
    );

    return ci ?? '';
  }

  @override
  Future<void> saveCi(String ci) async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await supabase.from('users').update({'CI': ci}).eq('id', user.id);
    } catch (e) {
      // 실패해도 앱이 죽지 않도록 예외는 넘김
    }
  }
}
