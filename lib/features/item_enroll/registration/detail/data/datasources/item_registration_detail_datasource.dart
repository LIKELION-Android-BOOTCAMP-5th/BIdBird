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
        'register-item-v2',
        body: <String, dynamic>{
          'itemId': itemId,
          'userId': userId,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> fetchFirstImageUrl(String itemId) async {
    try {
      final List<dynamic> imageRows = await _supabase
          .from('item_images')
          .select('image_url')
          .eq('item_id', itemId)
          .order('sort_order', ascending: true)
          .limit(1);

      if (imageRows.isEmpty) {
        return null;
      }

      final firstRow = imageRows.first;
      if (firstRow is Map<String, dynamic>) {
        final imageUrl = getNullableStringFromRow(firstRow, 'image_url');
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      return null;
    } catch (e) {
      // 이미지 조회 실패 시 null 반환
      return null;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await ItemSecurityUtils.requireAuthAndVerifyOwnership(
        _supabase,
        itemId,
      );


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



