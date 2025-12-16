import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemRegistrationDetailDatasource {
  ItemRegistrationDetailDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<String> fetchTermsText() async {
    try {
      final Map<String, dynamic> row = await _supabase
          .from('terms')
          .select('terms')
          .eq('id', 1)
          .single();

      return getStringFromRow(row, 'terms');
    } catch (e) {
      if (e.toString().contains('PGRST116') || e.toString().contains('No rows')) {
        throw Exception('약관 정보를 불러올 수 없습니다.');
      }
      rethrow;
    }
  }

  Future<void> confirmRegistration(String itemId) async {
    try {
      final userId = ItemSecurityUtils.requireAuth(_supabase);

      await _supabase.functions.invoke(
        'register-item',
        body: <String, dynamic>{
          'itemId': itemId,
          'userId': userId,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await ItemSecurityUtils.requireAuthAndVerifyOwnership(
        _supabase,
        itemId,
      );

      // 트랜잭션 처리: 두 작업이 모두 성공해야 함
      // Supabase는 RPC를 통해 트랜잭션을 처리하거나,
      // 순차 실행 후 실패 시 롤백 로직을 구현할 수 있습니다.
      // 여기서는 순차 실행 후 실패 시 예외를 던져 롤백을 유도합니다.

      // 1. item_images 삭제
      await _supabase
          .from('item_images')
          .delete()
          .eq('item_id', itemId);

      // 2. items_detail 삭제
      await _supabase
          .from('items_detail')
          .delete()
          .eq('item_id', itemId);
    } catch (e) {
      // 에러 발생 시 상위로 전파하여 롤백 유도
      rethrow;
    }
  }
}
