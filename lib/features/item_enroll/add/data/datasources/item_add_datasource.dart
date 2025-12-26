import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:flutter/foundation.dart';

class ItemAddDatasource {
  final _supabase = SupabaseManager.shared.supabase;

  Future<ItemRegistrationData> saveItem({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    String? editingItemId,
    String? thumbnailUrl,
  }) async {
    final isEdit = editingItemId != null && editingItemId.isNotEmpty;
    String itemId;

    if (isEdit) {
      itemId = editingItemId;
      await _updateItemDirect(
        itemId: itemId,
        entity: entity,
        imageUrls: imageUrls,
        documentUrls: entity.documentUrls,
        primaryImageIndex: primaryImageIndex,
        thumbnailUrl: thumbnailUrl,
      );
    } else {
      itemId = await _createItemDirect(
        entity: entity,
        imageUrls: imageUrls,
        documentUrls: entity.documentUrls,
        primaryImageIndex: primaryImageIndex,
        thumbnailUrl: thumbnailUrl,
      );
    }

    // documentNames are now passed directly into the RPC call in _createItemDirect / _updateItemDirect

    // Return success data directly without fetching (we already have all the info)
    return ItemRegistrationData(
      id: itemId,
      title: entity.title,
      description: entity.description,
      startPrice: entity.startPrice,
      instantPrice: entity.instantPrice,
      auctionDurationHours: entity.auctionDurationHours.toInt(),
      thumbnailUrl: thumbnailUrl ?? '',
      keywordTypeId: entity.keywordTypeId,
      statusText: '등록 완료',
    );
  }

  /// 100% Reliable direct Supabase RPC call
  Future<String> _createItemDirect({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required List<String> documentUrls,
    required int primaryImageIndex,
    String? thumbnailUrl,
  }) async {
    try {
      final validImageUrls = imageUrls.where((url) => url.isNotEmpty).toList();
      final validDocumentUrls = documentUrls.where((url) => url.isNotEmpty).toList();
      
      final params = {
        'p_seller_id': _supabase.auth.currentUser?.id,
        'p_title': entity.title,
        'p_description': entity.description,
        'p_start_price': entity.startPrice,
        'p_buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
        'p_keyword_type': entity.keywordTypeId,
        'p_duration_minutes': (entity.auctionDurationHours * 60).toInt(),
        'p_thumbnail_url': thumbnailUrl,
        'p_image_urls': validImageUrls,
        'p_document_urls': validDocumentUrls,
        'p_document_names': entity.documentNames ?? [],
        'p_file_sizes': entity.documentSizes ?? [],
      };
      
      final result = await _supabase.rpc('create_item_v2', params: params);

      if (result == null) throw Exception('Failed to get itemId from RPC');
      return result.toString();
    } catch (e) {
      throw Exception('Failed to create item (Direct): $e');
    }
  }

  /// 100% Reliable direct Supabase RPC call for updates
  Future<void> _updateItemDirect({
    required String itemId,
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required List<String> documentUrls,
    required int primaryImageIndex,
    String? thumbnailUrl,
  }) async {
    try {
      final validImageUrls = imageUrls.where((url) => url.isNotEmpty).toList();
      final validDocumentUrls = documentUrls.where((url) => url.isNotEmpty).toList();

      final params = {
        'p_item_id': itemId,
        'p_seller_id': _supabase.auth.currentUser?.id,
        'p_title': entity.title,
        'p_description': entity.description,
        'p_start_price': entity.startPrice,
        'p_buy_now_price': entity.instantPrice > 0 ? entity.instantPrice : null,
        'p_keyword_type': entity.keywordTypeId,
        'p_duration_hours': entity.auctionDurationHours,
        'p_thumbnail_url': thumbnailUrl,
        'p_image_urls': validImageUrls,
        'p_document_urls': validDocumentUrls,
        'p_document_names': entity.documentNames ?? [],
        'p_file_sizes': entity.documentSizes ?? [],
      };

      await _supabase.rpc('update_item_v2', params: params);
    } catch (e) {
      throw Exception('Failed to update item (Direct): $e');
    }
  }

}
