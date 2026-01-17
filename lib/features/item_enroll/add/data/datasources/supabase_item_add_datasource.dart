import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/item/item_registration_validator.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_data.dart';
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

    // Use the new atomic registration RPC
    final String itemId;
    final dynamic result = await _supabase.rpc(
      'create_and_register_item',
      params: <String, dynamic>{
        'p_seller_id': userId,
        'p_title': entity.title,
        'p_description': entity.description,
        'p_start_price': entity.startPrice,
        'p_buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
        'p_keyword_type': entity.keywordTypeId,
        'p_duration_minutes': entity.auctionDurationHours * 60,
        'p_image_urls': imageUrls,
        'p_document_urls': entity.documentUrls,
        'p_document_names': entity.documentNames ?? [],
        'p_file_sizes': entity.documentSizes ?? [],
        'p_thumbnail_url': thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls[primaryImageIndex] : null),
      },
    );

    itemId = result.toString();

    final finalThumbnailUrl = thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls[primaryImageIndex] : '');

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
