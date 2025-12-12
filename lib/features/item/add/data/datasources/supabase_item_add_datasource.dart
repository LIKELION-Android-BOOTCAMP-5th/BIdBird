import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/core/utils/item/item_registration_validator.dart';
import 'package:bidbird/features/item/add/model/item_add_entity.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
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
      throw Exception(ItemRegistrationErrorMessages.loginRequired);
    }

    // 공통 검증 로직 사용
    ItemRegistrationValidator.validateForServer(
      title: entity.title,
      description: entity.description,
      keywordTypeId: entity.keywordTypeId,
      startPrice: entity.startPrice,
      instantPrice: entity.instantPrice,
      imageUrls: imageUrls,
      auctionDurationHours: entity.auctionDurationHours,
    );

    late final String itemId;

    if (editingItemId != null) {
      itemId = editingItemId;

      await _supabase.from('items_detail').update(<String, dynamic>{
        'title': entity.title,
        'description': entity.description,
        'start_price': entity.startPrice,
        'buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
        'keyword_type': entity.keywordTypeId,
        'auction_duration_hours': entity.auctionDurationHours,
      }).eq('item_id', itemId);

      await _supabase.from('item_images').delete().eq('item_id', itemId);
    } else {
      final dynamic result = await _supabase.rpc(
        'register_item',
        params: <String, dynamic>{
          'p_seller_id': user.id,
          'p_title': entity.title,
          'p_description': entity.description,
          'p_start_price': entity.startPrice,
          'p_buy_now_price':
              entity.instantPrice > 0 ? entity.instantPrice : null,
          'p_keyword_type': entity.keywordTypeId,
          'p_duration_minutes': entity.auctionDurationHours * 60,
        },
      );

      itemId = result.toString();

      await _supabase.from('items_detail').update(<String, dynamic>{
        'auction_duration_hours': entity.auctionDurationHours,
      }).eq('item_id', itemId);
    }

    final List<Map<String, dynamic>> imageRows = <Map<String, dynamic>>[];
    for (int i = 0; i < imageUrls.length && i < ItemImageLimits.maxImageCount; i++) {
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

    int thumbnailIndex = 0;
    if (primaryImageIndex >= 0 && primaryImageIndex < imageUrls.length) {
      thumbnailIndex = primaryImageIndex;
    }

    await _supabase.from('items_detail').update(<String, dynamic>{
      'thumbnail_image': imageUrls[thumbnailIndex],
    }).eq('item_id', itemId);

    return ItemRegistrationData(
      id: itemId,
      title: entity.title,
      description: entity.description,
      startPrice: entity.startPrice,
      instantPrice: entity.instantPrice,
      auctionDurationHours: entity.auctionDurationHours,
      thumbnailUrl: imageUrls[thumbnailIndex],
      keywordTypeId: entity.keywordTypeId,
    );
  }
}
