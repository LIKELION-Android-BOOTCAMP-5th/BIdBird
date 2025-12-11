import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/add/model/edit_item_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditItemRemoteDataSource {
  EditItemRemoteDataSource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<EditItemEntity> fetchItemForEdit(String itemId) async {
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
        .cast<Map<String, dynamic>>()
        .map((e) => (e['image_url'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .toList();

    return EditItemEntity(
      title: (row['title'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      startPrice: (row['start_price'] as num?)?.toInt() ?? 0,
      buyNowPrice: (row['buy_now_price'] as num?)?.toInt() ?? 0,
      keywordTypeId: (row['keyword_type'] as num?)?.toInt() ?? 0,
      // items_detail.auction_duration_hours 컬럼은 실제 시간 값(4, 12, 24 등)을 그대로 보관합니다.
      auctionDurationHours:
          (row['auction_duration_hours'] as num?)?.toInt() ?? 4,
      imageUrls: imageUrls,
    );
  }
}
