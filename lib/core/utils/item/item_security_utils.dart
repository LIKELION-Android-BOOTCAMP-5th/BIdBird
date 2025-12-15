import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 아이템 관련 보안 유틸리티
class ItemSecurityUtils {
  /// 현재 로그인한 사용자 ID를 반환합니다.
  /// 로그인하지 않은 경우 예외를 던집니다.
  static String requireAuth(SupabaseClient supabase) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception(ItemRegistrationErrorMessages.loginRequired);
    }
    return user.id;
  }

  /// 아이템의 소유권을 검증합니다.
  /// 소유자가 아닌 경우 예외를 던집니다.
  static Future<void> verifyItemOwnership(
    SupabaseClient supabase,
    String itemId,
    String userId,
  ) async {
    try {
      final row = await supabase
          .from('items_detail')
          .select('seller_id')
          .eq('item_id', itemId)
          .maybeSingle();

      if (row == null) {
        throw Exception('아이템을 찾을 수 없습니다.');
      }

      final String? sellerId = row['seller_id']?.toString();
      if (sellerId == null || sellerId != userId) {
        throw Exception('이 아이템을 수정할 권한이 없습니다.');
      }
    } catch (e) {
      if (e.toString().contains('권한이 없습니다') ||
          e.toString().contains('찾을 수 없습니다')) {
        rethrow;
      }
      throw Exception('소유권 확인 중 오류가 발생했습니다: $e');
    }
  }

  /// 아이템의 소유권을 검증하고 사용자 ID를 반환합니다.
  /// 로그인 체크와 소유권 검증을 한 번에 수행합니다.
  static Future<String> requireAuthAndVerifyOwnership(
    SupabaseClient supabase,
    String itemId,
  ) async {
    final userId = requireAuth(supabase);
    await verifyItemOwnership(supabase, itemId, userId);
    return userId;
  }
}

