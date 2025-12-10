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
  Future<bool> requestIdentityVerification(BuildContext context) async {
    // 포트원 위젯을 통해 imp_uid 수신
    final impUid = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const KgInicisIdentityWebViewScreen(),
      ),
    );
    if (impUid == null || impUid.isEmpty) {
      return false;
    }

    // Supabase Edge Function(identity-complete)에 imp_uid 전달
    try {
      final supabase = SupabaseManager.shared.supabase;
      final user = supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final response = await supabase.functions.invoke(
        'identity-complete',
        body: {
          'imp_uid': impUid,
          'user_id': user.id,
        },
      );

      // Edge Function에서 { success: true } 형태로 응답한다고 가정
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return true;
      }

      return false;
    } catch (e) {
      // 함수 호출 실패 시 인증 실패로 간주
      return false;
    }
  }
}
