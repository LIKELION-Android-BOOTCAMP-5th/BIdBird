import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemRegistrationDetailDatasource {
  ItemRegistrationDetailDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<_RegisterItemPayload> _fetchRegisterItem(String itemId) async {
    final response = await _supabase.rpc(
      'get_register_item',
      params: {'item_id_param': itemId},
    );

    if (response is! Map<String, dynamic>) {
      throw Exception('잘못된 응답 형식입니다.');
    }

    final images =
        (response['images'] as List?)
            ?.whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];

    final item = response['item'] as Map<String, dynamic>?;

    return _RegisterItemPayload(images: images, item: item);
  }

  Future<String> fetchTermsText() async {
    try {
      final Map<String, dynamic> row = await _supabase
          .from('terms')
          .select('terms')
          .eq('id', 1)
          .single();

      return getStringFromRow(row, 'terms');
    } catch (e) {
      if (e.toString().contains('PGRST116') ||
          e.toString().contains('No rows')) {
        throw Exception('약관 정보를 불러올 수 없습니다.');
      }
      rethrow;
    }
  }

  Future<void> confirmRegistration(String itemId) async {
    try {
      final userId = ItemSecurityUtils.requireAuth(_supabase);

      await _supabase.rpc(
        'register_item_v2',
        params: {'item_id_param': itemId, 'user_id_param': userId},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> fetchFirstImageUrl(String itemId) async {
    try {
      final payload = await _fetchRegisterItem(itemId);
      if (payload.images.isNotEmpty) {
        return payload.images.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> fetchAllImageUrls(String itemId) async {
    try {
      final payload = await _fetchRegisterItem(itemId);
      return payload.images;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await ItemSecurityUtils.requireAuthAndVerifyOwnership(_supabase, itemId);

      // 1. item_images 삭제
      await _supabase.from('item_images').delete().eq('item_id', itemId);

      // 2. items_detail 삭제
      await _supabase.from('items_detail').delete().eq('item_id', itemId);
    } catch (e) {
      // 에러 발생 시 상위로 전파하여 롤백 유도
      rethrow;
    }
  }
}

class _RegisterItemPayload {
  _RegisterItemPayload({required this.images, this.item});

  final List<String> images;
  final Map<String, dynamic>? item;
}
