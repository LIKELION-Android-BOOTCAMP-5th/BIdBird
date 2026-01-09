import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_validator.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
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
    String? thumbnailUrl,
  }) async {
    final userId = ItemSecurityUtils.requireAuth(_supabase);

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

    late String itemId;

    if (editingItemId != null) {
      itemId = editingItemId;

      await ItemSecurityUtils.verifyItemOwnership(_supabase, itemId, userId);

      try {
        final auctionRow = await _supabase
            .from('auctions')
            .select('auction_status_code')
            .eq('item_id', itemId)
            .eq('round', 1)
            .maybeSingle();

        if (auctionRow != null) {
          final auctionStatusCode = getIntFromRow(auctionRow, 'auction_status_code');
          if (auctionStatusCode == AuctionStatusCode.failed) {
            itemId = (await _supabase.rpc(
              'register_item',
              params: <String, dynamic>{
                'p_seller_id': userId,
                'p_title': entity.title,
                'p_description': entity.description,
                'p_start_price': entity.startPrice,
                'p_buy_now_price':
                    entity.instantPrice > 0 ? entity.instantPrice : null,
                'p_keyword_type': entity.keywordTypeId,
                'p_duration_minutes': entity.auctionDurationHours * 60,
              },
            )).toString();

            await _supabase.from('items_detail').update(<String, dynamic>{
              'auction_duration_hours': entity.auctionDurationHours,
            }).eq('item_id', itemId);
          } else {
            // 수정 모드로 진행
            await _supabase.from('items_detail').update(<String, dynamic>{
              'title': entity.title,
              'description': entity.description,
              'start_price': entity.startPrice,
              'buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
              'keyword_type': entity.keywordTypeId,
              'auction_duration_hours': entity.auctionDurationHours,
            }).eq('item_id', itemId);

            await _supabase.from('item_images').delete().eq('item_id', itemId);
          }
        } else {
          // auction 정보가 없으면 수정 모드로 진행
          await _supabase.from('items_detail').update(<String, dynamic>{
            'title': entity.title,
            'description': entity.description,
            'start_price': entity.startPrice,
            'buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
            'keyword_type': entity.keywordTypeId,
            'auction_duration_hours': entity.auctionDurationHours,
          }).eq('item_id', itemId);

          await _supabase.from('item_images').delete().eq('item_id', itemId);
        }
      } catch (e) {
        // 오류 발생 시 기존 동작 유지 (수정 모드로 진행)
        await _supabase.from('items_detail').update(<String, dynamic>{
          'title': entity.title,
          'description': entity.description,
          'start_price': entity.startPrice,
          'buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
          'keyword_type': entity.keywordTypeId,
          'auction_duration_hours': entity.auctionDurationHours,
        }).eq('item_id', itemId);

        await _supabase.from('item_images').delete().eq('item_id', itemId);
      }
    } else {
      final dynamic result = await _supabase.rpc(
        'register_item',
        params: <String, dynamic>{
          'p_seller_id': userId,
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
    // 중복 제거된 이미지 URL 목록 사용
    final distinctImageUrls = imageUrls.toSet().toList();
    for (int i = 0; i < distinctImageUrls.length && i < ItemImageLimits.maxImageCount; i++) {
      imageRows.add(<String, dynamic>{
        'item_id': itemId,
        'image_url': distinctImageUrls[i],
        'sort_order': i + 1,
      });
    }

    if (imageRows.isNotEmpty) {
      await _supabase.from('item_images').insert(imageRows);
    }

    // 썸네일 URL 결정 (전달받은 썸네일 URL이 있으면 사용, 없으면 primaryImageIndex의 이미지 URL 사용)
    String finalThumbnailUrl;
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      finalThumbnailUrl = thumbnailUrl;
    } else {
      int thumbnailIndex = 0;
      if (primaryImageIndex >= 0 && primaryImageIndex < imageUrls.length) {
        thumbnailIndex = primaryImageIndex;
      }
      finalThumbnailUrl = imageUrls[thumbnailIndex];
    }

    await _supabase.from('items_detail').update(<String, dynamic>{
      'thumbnail_image': finalThumbnailUrl,
    }).eq('item_id', itemId);

    return ItemRegistrationData(
      id: itemId,
      title: entity.title,
      description: entity.description,
      startPrice: entity.startPrice,
      instantPrice: entity.instantPrice,
      auctionDurationHours: entity.auctionDurationHours,
      thumbnailUrl: finalThumbnailUrl,
      keywordTypeId: entity.keywordTypeId,
      statusText: '등록 대기',
    );
  }
}
