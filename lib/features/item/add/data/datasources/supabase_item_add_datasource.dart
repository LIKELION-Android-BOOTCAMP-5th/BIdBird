import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/add/model/item_add_entity.dart';
import 'package:bidbird/features/item/item_registration_list/model/item_registration_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseItemAddDatasource {
  SupabaseItemAddDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<ItemRegistrationData> saveItem({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    String? editingItemId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('로그인 정보가 없습니다. 다시 로그인 해주세요.');
    }

    Map<String, dynamic> row;

    if (editingItemId == null) {
      final Map<String, dynamic> inserted = await _supabase
          .from('items')
          .insert(entity.toJson(sellerId: user.id))
          .select(
            'id, title, description, start_price, buy_now_price, keyword_type',
          )
          .single();
      row = inserted;
    } else {
      final Map<String, dynamic> updateJson = entity.toJson(sellerId: user.id)
        ..remove('seller_id')
        ..remove('current_price')
        ..remove('bidding_count')
        ..remove('status');

      final Map<String, dynamic> updated = await _supabase
          .from('items')
          .update(updateJson)
          .eq('id', editingItemId)
          .select(
            'id, title, description, start_price, buy_now_price, keyword_type',
          )
          .single();
      row = updated;
    }

    final String itemId = row['id'].toString();

    if (editingItemId != null) {
      await _supabase.from('item_images').delete().eq('item_id', itemId);
    }

    if (imageUrls.isNotEmpty) {
      final List<Map<String, dynamic>> imageRows = <Map<String, dynamic>>[];
      for (int i = 0; i < imageUrls.length && i < 10; i++) {
        imageRows.add(<String, dynamic>{
          'item_id': itemId,
          'image_url': imageUrls[i],
          'sort_order': i + 1,
        });
      }

      if (imageRows.isNotEmpty) {
        await _supabase.from('item_images').insert(imageRows);
      }

      try {
        int index = 0;
        if (primaryImageIndex >= 0 && primaryImageIndex < imageUrls.length) {
          index = primaryImageIndex;
        }
        await _supabase.functions.invoke(
          'create-thumbnail',
          body: <String, dynamic>{
            'itemId': itemId,
            'imageUrl': imageUrls[index],
          },
        );
      } catch (e) {
        debugPrint('create-thumbnail error: $e');
      }
    }

    int thumbnailIndex = 0;
    if (imageUrls.isNotEmpty) {
      if (primaryImageIndex >= 0 && primaryImageIndex < imageUrls.length) {
        thumbnailIndex = primaryImageIndex;
      }
    }

    return ItemRegistrationData(
      id: itemId,
      title: row['title']?.toString() ?? entity.title,
      description: row['description']?.toString() ?? entity.description,
      startPrice: (row['start_price'] as num?)?.toInt() ?? entity.startPrice,
      instantPrice:
          (row['buy_now_price'] as num?)?.toInt() ?? entity.instantPrice,
      thumbnailUrl: imageUrls.isNotEmpty ? imageUrls[thumbnailIndex] : null,
      keywordTypeId: (row['keyword_type'] as num?)?.toInt(),
    );
  }
}
