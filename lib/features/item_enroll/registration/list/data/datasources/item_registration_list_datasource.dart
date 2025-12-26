import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemRegistrationListDatasource {
  ItemRegistrationListDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<List<ItemRegistrationData>> fetchMyPendingItems() async {
    try {
      final userId = ItemSecurityUtils.requireAuth(_supabase);

      // Edge Function 호출로 매물 등록 대기 리스트를 조회
      final response = await _supabase.functions.invoke(
        'get-register-list-item',
        body: <String, dynamic>{
          'userId': userId,
        },
      );

      final dynamic data = response.data;
      if (data is! List) {
        throw Exception('잘못된 응답 형식입니다.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map<ItemRegistrationData>((row) {
        return ItemRegistrationData(
          id: getStringFromRow(row, 'item_id'),
          title: getStringFromRow(row, 'title'),
          description: getStringFromRow(row, 'description'),
          startPrice: getIntFromRow(row, 'start_price'),
          instantPrice: getIntFromRow(row, 'buy_now_price'),
          auctionDurationHours: getIntFromRow(row, 'auction_duration_hours'),
          thumbnailUrl: getNullableStringFromRow(row, 'thumbnail_image'),
          keywordTypeId: getNullableIntFromRow(row, 'keyword_type'),
          statusText: _deriveStatus(row['is_agreed']),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  String _deriveStatus(dynamic rawIsAgreed) {
    if (rawIsAgreed == null) return '등록 대기';
    if (rawIsAgreed is String && rawIsAgreed.trim().isEmpty) return '등록 대기';
    return '승인 완료';
  }
}



