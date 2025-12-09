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
    if (imageUrls.isEmpty) {
      throw Exception('이미지는 최소 1장이 필요합니다.');
    }
    if (imageUrls.length > 10) {
      throw Exception('이미지는 최대 10장까지 등록 가능합니다.');
    }

    if (entity.title.trim().isEmpty) {
      throw Exception('제목을 입력해주세요.');
    }
    if (entity.title.length > 20) {
      throw Exception('제목은 20자 이하여야 합니다.');
    }
    if (entity.description.isNotEmpty && entity.description.length > 1000) {
      throw Exception('본문은 1000자 이하여야 합니다.');
    }
    if (entity.startPrice < 10000) {
      throw Exception('시작 가격은 10,000원 이상이어야 합니다.');
    }
    if (entity.instantPrice > 0 && entity.instantPrice <= entity.startPrice) {
      throw Exception('즉시 구매가는 시작 가격보다 커야 합니다.');
    }
    if (entity.keywordTypeId <= 0) {
      throw Exception('카테고리를 선택해주세요.');
    }
    if (entity.auctionDurationHours <= 0) {
      throw Exception('경매 기간을 설정해주세요.');
    }

    final dynamic result = await _supabase.rpc(
      'register_item',
      params: <String, dynamic>{
        'p_seller_id': user.id,
        'p_title': entity.title,
        'p_description': entity.description,
        'p_start_price': entity.startPrice,
        'p_buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
        'p_keyword_type': entity.keywordTypeId,
        'p_duration_minutes': entity.auctionDurationHours * 60,
      },
    );

    final String itemId = result.toString();

    if (editingItemId != null) {
      await _supabase.from('item_images').delete().eq('item_id', itemId);
    }

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
      thumbnailUrl: imageUrls[thumbnailIndex],
      keywordTypeId: entity.keywordTypeId,
    );
  }
}
