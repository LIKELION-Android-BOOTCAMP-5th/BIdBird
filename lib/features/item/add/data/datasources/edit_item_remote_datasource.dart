import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:bidbird/features/item/add/model/edit_item_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditItemRemoteDataSource {
  EditItemRemoteDataSource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<EditItemEntity> fetchItemForEdit(String itemId) async {
    await ItemSecurityUtils.requireAuthAndVerifyOwnership(_supabase, itemId);

    try {
      final Map<String, dynamic> row = await _supabase
          .from('items_detail')
          .select(
            'title, description, start_price, buy_now_price, keyword_type, auction_duration_hours',
          )
          .eq('item_id', itemId)
          .single();

      final List<dynamic> imageRows = await _supabase
          .from('item_images')
          .select('image_url, sort_order')
          .eq('item_id', itemId)
          .order('sort_order');

      final List<String> imageUrls = imageRows
          .whereType<Map<String, dynamic>>()
          .map((e) => getStringFromRow(e, 'image_url'))
          .where((url) => url.isNotEmpty)
          .toList();

      return EditItemEntity(
        title: getStringFromRow(row, 'title'),
        description: getStringFromRow(row, 'description'),
        startPrice: getIntFromRow(row, 'start_price'),
        buyNowPrice: getIntFromRow(row, 'buy_now_price'),
        keywordTypeId: getIntFromRow(row, 'keyword_type'),
        auctionDurationHours: getIntFromRow(row, 'auction_duration_hours', 4),
        imageUrls: imageUrls,
      );
    } catch (e) {
      if (e.toString().contains('PGRST116') || e.toString().contains('No rows')) {
        throw Exception('아이템을 찾을 수 없습니다. 아이템이 삭제되었거나 존재하지 않습니다.');
      }
      rethrow;
    }
  }
}
