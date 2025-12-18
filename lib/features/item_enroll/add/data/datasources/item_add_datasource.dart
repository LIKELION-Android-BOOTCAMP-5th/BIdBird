import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_add_entity.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_registration_validator.dart' as validator;
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemAddDatasource {
  ItemAddDatasource({SupabaseClient? supabase})
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
    validator.ItemRegistrationValidator.validateForServer(
      title: entity.title,
      description: entity.description,
      keywordTypeId: entity.keywordTypeId,
      startPrice: entity.startPrice,
      instantPrice: entity.instantPrice,
      imageUrls: imageUrls,
      auctionDurationHours: entity.auctionDurationHours,
    );

    final isEdit = editingItemId != null && editingItemId.isNotEmpty;
    String itemId;

    if (isEdit) {
      // 수정 모드
      itemId = editingItemId!;
      await _updateItem(
        itemId: itemId,
        entity: entity,
        imageUrls: imageUrls,
        primaryImageIndex: primaryImageIndex,
        thumbnailUrl: thumbnailUrl,
      );
    } else {
      // 신규 등록 모드 - 엣지 펑션 사용
      itemId = await _createItem(
        entity: entity,
        imageUrls: imageUrls,
        primaryImageIndex: primaryImageIndex,
        userId: userId,
        thumbnailUrl: thumbnailUrl,
      );
    }

    // 등록/수정 후 아이템 정보 조회
    final itemData = await _fetchItemData(itemId);

    return ItemRegistrationData(
      id: getStringFromRow(itemData, 'item_id'),
      title: getStringFromRow(itemData, 'title'),
      description: getStringFromRow(itemData, 'description'),
      startPrice: getIntFromRow(itemData, 'start_price'),
      instantPrice: getIntFromRow(itemData, 'buy_now_price'),
      auctionDurationHours: getIntFromRow(itemData, 'auction_duration', 4),
      thumbnailUrl: getStringFromRow(itemData, 'thumbnail_image'),
      keywordTypeId: getIntFromRow(itemData, 'keyword_type'),
    );
  }

  Future<String> _createItem({
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    required String userId,
    String? thumbnailUrl,
  }) async {
    try {
      // 유효한 이미지 URL만 필터링 (빈 문자열이나 null 제거)
      final validImageUrls = imageUrls
          .where((url) => url.isNotEmpty)
          .toList();
      
      if (validImageUrls.isEmpty) {
        throw Exception('최소 1장의 이미지가 필요합니다.');
      }

      // 엣지 펑션(create-item)을 사용하여 최초 등록 처리
      // register_item RPC를 내부적으로 호출하여 items_detail과 auctions 테이블을 함께 생성
      final response = await _supabase.functions.invoke(
        'create-item',
        body: <String, dynamic>{
          'sellerId': userId,
          'title': entity.title,
          'description': entity.description,
          'startPrice': entity.startPrice,
          'buyNowPrice': entity.instantPrice > 0 ? entity.instantPrice : null,
          'keywordType': entity.keywordTypeId,
          'durationMinutes': entity.auctionDurationHours * 60,
          'auctionDurationHours': entity.auctionDurationHours,
          'imageUrls': validImageUrls,
          'primaryImageIndex': primaryImageIndex >= 0 && primaryImageIndex < validImageUrls.length 
              ? primaryImageIndex 
              : 0,
          'thumbnailUrl': thumbnailUrl,
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Failed to create item: No response data');
      }

      // response.data가 Map인 경우 에러 확인
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          final errorMessage = data['error'] as String? ?? 'Unknown error';
          final details = data['details'];
          if (details != null) {
            throw Exception('$errorMessage: $details');
          }
          throw Exception(errorMessage);
        }
        if (data['success'] == false) {
          final errorMessage = data['error'] as String? ?? 'Failed to create item';
          final details = data['details'];
          if (details != null) {
            throw Exception('$errorMessage: $details');
          }
          throw Exception(errorMessage);
        }
      }

      final itemId = data is Map<String, dynamic> 
          ? (data['itemId'] as String?)
          : null;
      
      if (itemId == null || itemId.isEmpty) {
        throw Exception('Failed to create item: itemId is null or empty');
      }

      return itemId;
    } catch (e) {
      // 이미 Exception이면 그대로 전달, 아니면 래핑
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create item: ${e.toString()}');
    }
  }

  Future<void> _updateItem({
    required String itemId,
    required ItemAddEntity entity,
    required List<String> imageUrls,
    required int primaryImageIndex,
    String? thumbnailUrl,
  }) async {
    // 기존 이미지 삭제
    await _supabase.from('item_images').delete().eq('item_id', itemId);

    // 아이템 정보 업데이트
    final updateData = <String, dynamic>{
      'title': entity.title,
      'description': entity.description,
      'start_price': entity.startPrice,
      'buy_now_price': entity.instantPrice,
      'keyword_type': entity.keywordTypeId,
      'auction_duration': entity.auctionDurationHours,
      // auction_start_at과 auction_end_at은 auctions 테이블에 저장되므로 items_detail에는 포함하지 않음
    };

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      updateData['thumbnail_image'] = thumbnailUrl;
    }

    await _supabase.from('items_detail').update(updateData).eq('item_id', itemId);

    // 새 이미지 등록
    await _insertImages(itemId, imageUrls, primaryImageIndex);
  }

  Future<void> _insertImages(
    String itemId,
    List<String> imageUrls,
    int primaryImageIndex,
  ) async {
    if (imageUrls.isEmpty) return;

    // item_images 테이블에는 is_primary 컬럼이 없음
    // 썸네일은 items_detail.thumbnail_image에 저장됨
    final imageData = imageUrls.asMap().entries.map((entry) {
      return {
        'item_id': itemId,
        'image_url': entry.value,
        'sort_order': entry.key,
      };
    }).toList();

    await _supabase.from('item_images').insert(imageData);
  }

  Future<String> _getLastInsertedItemId(String userId) async {
    final response = await _supabase
        .from('items_detail')
        .select('item_id')
        .eq('seller_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .single();

    return getStringFromRow(response, 'item_id');
  }

  Future<Map<String, dynamic>> _fetchItemData(String itemId) async {
    final response = await _supabase
        .from('items_detail')
        .select()
        .eq('item_id', itemId)
        .single();

    return response as Map<String, dynamic>;
  }
}

