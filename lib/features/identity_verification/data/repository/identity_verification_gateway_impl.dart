import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/identity_verification/data/repository/identity_verification_gateway.dart';
import 'package:bidbird/features/identity_verification/screen/identity_verification_webview_screen.dart';
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
  Future<bool> requestIdentityVerification(BuildContext context) async {
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
      return false;
    }

    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final response = await supabase.functions.invoke(
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
